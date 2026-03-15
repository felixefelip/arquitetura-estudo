require "spec_helper"
require "rbs_usage_analyzer"
require "tmpdir"
require "fileutils"

RSpec.describe RbsUsageAnalyzer do
  # Helper: cria arquivos temporários e retorna os paths
  def with_temp_files(files, &block)
    Dir.mktmpdir do |dir|
      paths = files.map do |rel_path, content|
        path = File.join(dir, rel_path)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        path
      end
      block.call(dir, paths)
    end
  end

  # ─── ClassNameExtractor ──────────────────────────────────────────

  describe RbsUsageAnalyzer::ClassNameExtractor do
    def extract_class(source)
      result = Prism.parse(source)
      visitor = described_class.new
      result.value.accept(visitor)
      visitor.class_name
    end

    it "extrai nome de classe simples" do
      expect(extract_class("class Foo; end")).to eq("Foo")
    end

    it "extrai classe dentro de módulos inline" do
      source = <<~RUBY
        module Academico::Aluno
          class Entity
          end
        end
      RUBY
      expect(extract_class(source)).to eq("Academico::Aluno::Entity")
    end

    it "extrai classe com módulos aninhados" do
      source = <<~RUBY
        module Academico
          module Aluno
            class Email
            end
          end
        end
      RUBY
      expect(extract_class(source)).to eq("Academico::Aluno::Email")
    end
  end

  # ─── OptionalParamExtractor ──────────────────────────────────────

  describe RbsUsageAnalyzer::OptionalParamExtractor do
    def extract_optionals(source)
      result = Prism.parse(source)
      visitor = described_class.new
      result.value.accept(visitor)
      visitor.optional_params
    end

    it "identifica keyword params com valor default" do
      source = <<~RUBY
        class Foo
          def initialize(nome:, senha: nil)
          end
        end
      RUBY

      result = extract_optionals(source)
      expect(result).to include("senha")
      expect(result).not_to include("nome")
    end

    it "identifica múltiplos params opcionais" do
      source = <<~RUBY
        class Foo
          def initialize(a:, b: "x", c: 42, d:)
          end
        end
      RUBY

      result = extract_optionals(source)
      expect(result).to include("b", "c")
      expect(result).not_to include("a", "d")
    end

    it "retorna vazio quando não há initialize" do
      source = <<~RUBY
        class Foo
          def call; end
        end
      RUBY

      expect(extract_optionals(source)).to be_empty
    end
  end

  # ─── InitializeBodyAnalyzer ──────────────────────────────────────

  describe RbsUsageAnalyzer::InitializeBodyAnalyzer do
    def analyze(source)
      result = Prism.parse(source)
      visitor = described_class.new
      result.value.accept(visitor)
      visitor
    end

    it "detecta self.attr = param" do
      source = <<~RUBY
        class Foo
          def initialize(nome:)
            self.nome = nome
          end
        end
      RUBY

      visitor = analyze(source)
      expect(visitor.self_assignments).to include("nome")
      expect(visitor.self_assignments["nome"][:kind]).to eq(:param)
      expect(visitor.self_assignments["nome"][:name]).to eq("nome")
    end

    it "detecta self.attr = Klass.new(...)" do
      source = <<~RUBY
        class Entity
          def initialize(email:)
            self.email = Email.new(endereco: email)
          end
        end
      RUBY

      visitor = analyze(source)
      expect(visitor.self_assignments["email"][:kind]).to eq(:constant)
      expect(visitor.self_assignments["email"][:type]).to eq("Email")
    end

    it "detecta self.attr = ::Shared::Cpf.new(numero: cpf)" do
      source = <<~RUBY
        class Entity
          def initialize(cpf:)
            self.cpf = ::Shared::Cpf.new(numero: cpf)
          end
        end
      RUBY

      visitor = analyze(source)
      expect(visitor.self_assignments["cpf"][:kind]).to eq(:constant)
      expect(visitor.self_assignments["cpf"][:type]).to eq("::Shared::Cpf")
    end

    it "extrai keyword defaults" do
      source = <<~RUBY
        class Foo
          def initialize(repo: MyRepo.new, name: "default", count: 42)
            self.repo = repo
            self.name = name
          end
        end
      RUBY

      visitor = analyze(source)
      expect(visitor.keyword_defaults["repo"]).to eq("MyRepo")
      expect(visitor.keyword_defaults["name"]).to eq("String")
      expect(visitor.keyword_defaults["count"]).to eq("Integer")
    end

    it "ignora nil como tipo de default (indica opcional, não tipo nil)" do
      source = <<~RUBY
        class Foo
          def initialize(senha: nil)
            self.senha = senha
          end
        end
      RUBY

      visitor = analyze(source)
      expect(visitor.keyword_defaults).not_to have_key("senha")
    end
  end

  # ─── ClassMemberCollector ────────────────────────────────────────

  describe RbsUsageAnalyzer::ClassMemberCollector do
    def collect(source)
      result = Prism.parse(source)
      comments = result.comments
      lines = source.lines
      visitor = described_class.new(comments: comments, lines: lines)
      result.value.accept(visitor)
      visitor
    end

    it "coleta attr_reader com tipo inline" do
      source = <<~RUBY
        class Foo
          attr_reader :nome #: String
        end
      RUBY

      collector = collect(source)
      member = collector.members.find { |m| m.name == "nome" }
      expect(member).not_to be_nil
      expect(member.kind).to eq(:attr_reader)
      expect(member.signature).to eq("nome: String")
    end

    it "coleta attr_accessor sem tipo como untyped" do
      source = <<~RUBY
        class Foo
          attr_accessor :idade
        end
      RUBY

      collector = collect(source)
      member = collector.members.find { |m| m.name == "idade" }
      expect(member.kind).to eq(:attr_accessor)
      expect(member.signature).to eq("idade: untyped")
    end

    it "coleta método com assinatura rbs-inline (#:)" do
      source = <<~RUBY
        class Foo
          #: -> void
          def call
          end
        end
      RUBY

      collector = collect(source)
      member = collector.members.find { |m| m.name == "call" }
      expect(member.kind).to eq(:method)
      expect(member.signature).to eq("call: -> void")
    end

    it "coleta método com assinatura @rbs" do
      source = <<~RUBY
        class Foo
          # @rbs (nome: String) -> void
          def initialize(nome:)
          end
        end
      RUBY

      collector = collect(source)
      member = collector.members.find { |m| m.name == "initialize" }
      expect(member.signature).to eq("initialize: (nome: String) -> void")
    end

    it "rastreia visibilidade private" do
      source = <<~RUBY
        class Foo
          def call; end

          private

          attr_accessor :nome
          def helper; end
        end
      RUBY

      collector = collect(source)
      expect(collector.members.find { |m| m.name == "call" }.visibility).to eq(:public)
      expect(collector.members.find { |m| m.name == "nome" }.visibility).to eq(:private)
      expect(collector.members.find { |m| m.name == "helper" }.visibility).to eq(:private)
    end

    it "detecta superclass" do
      source = <<~RUBY
        class MyController < ApplicationController
          def index; end
        end
      RUBY

      collector = collect(source)
      expect(collector.superclass_name).to eq("ApplicationController")
    end

    it "usa void como return type para actions de controllers" do
      source = <<~RUBY
        class MyController < ApplicationController
          def create; end
          def index; end
        end
      RUBY

      collector = collect(source)
      create_member = collector.members.find { |m| m.name == "create" }
      expect(create_member.signature).to include("-> void")
    end

    it "infere return type de métodos simples" do
      source = <<~RUBY
        class Foo
          def build_name
            "hello"
          end

          def build_count
            42
          end
        end
      RUBY

      collector = collect(source)
      expect(collector.members.find { |m| m.name == "build_name" }.signature).to include("-> String")
      expect(collector.members.find { |m| m.name == "build_count" }.signature).to include("-> Integer")
    end

    it "gera assinatura com keyword params" do
      source = <<~RUBY
        class Foo
          def initialize(nome:, email:, senha: nil)
          end
        end
      RUBY

      collector = collect(source)
      member = collector.members.find { |m| m.name == "initialize" }
      expect(member.signature).to include("nome: untyped")
      expect(member.signature).to include("email: untyped")
      expect(member.signature).to include("?senha: untyped")
    end
  end

  # ─── ClassBodyAttrAnalyzer ──────────────────────────────────────

  describe RbsUsageAnalyzer::ClassBodyAttrAnalyzer do
    def analyze(source, attr_names)
      result = Prism.parse(source)
      visitor = described_class.new(attr_names: attr_names.to_set)
      result.value.accept(visitor)
      visitor.attr_types
    end

    it "detecta self.attr = Klass.new() em qualquer método" do
      source = <<~RUBY
        class Foo
          attr_accessor :widget

          def setup
            self.widget = Widget.new(name: "test")
          end
        end
      RUBY

      types = analyze(source, ["widget"])
      expect(types["widget"]).to eq("Widget")
    end

    it "detecta variável local com mesmo nome de attr" do
      source = <<~RUBY
        class Foo
          attr_accessor :result

          def compute
            result = Something.new
          end
        end
      RUBY

      types = analyze(source, ["result"])
      expect(types["result"]).to eq("Something")
    end
  end

  # ─── NewCallCollector ────────────────────────────────────────────

  describe RbsUsageAnalyzer::NewCallCollector do
    def collect_usages(source, target_class:, method_return_types: {}, local_var_types: {})
      result = Prism.parse(source)
      visitor = described_class.new(
        target_class: target_class,
        method_return_types: method_return_types,
        local_var_types: local_var_types
      )
      result.value.accept(visitor)
      visitor.usages
    end

    it "coleta kwargs de chamadas .new com literais" do
      source = <<~RUBY
        Foo.new(nome: "teste", idade: 42)
      RUBY

      usages = collect_usages(source, target_class: "Foo")
      expect(usages.size).to eq(1)
      expect(usages.first["nome"]).to eq("String")
      expect(usages.first["idade"]).to eq("Integer")
    end

    it "resolve variáveis locais atribuídas via method call" do
      source = <<~RUBY
        def test
          dto = build_dto
          Foo.new(data: dto)
        end
      RUBY

      usages = collect_usages(source,
        target_class: "Foo",
        method_return_types: { "build_dto" => "MyDto" })
      expect(usages.first["data"]).to eq("MyDto")
    end

    it "resolve variáveis locais atribuídas via Klass.new" do
      source = <<~RUBY
        def test
          client = Client::Entity.new(name: "x")
          Enroll.new(client: client)
        end
      RUBY

      usages = collect_usages(source, target_class: "Enroll")
      expect(usages.first["client"]).to eq("Client::Entity")
    end

    it "resolve AR finder methods como tipo do receiver" do
      source = <<~RUBY
        def test
          record = Record.find_by!(email: "x")
          Target.new(record: record)
        end
      RUBY

      usages = collect_usages(source, target_class: "Target")
      expect(usages.first["record"]).to eq("Record")
    end

    it "match relativo: Email == Academico::Aluno::Email" do
      source = <<~RUBY
        Email.new(endereco: "test@email.com")
      RUBY

      usages = collect_usages(source, target_class: "Academico::Aluno::Email")
      expect(usages.size).to eq(1)
      expect(usages.first["endereco"]).to eq("String")
    end

    it "não faz match parcial incorreto" do
      source = <<~RUBY
        SuperEmail.new(endereco: "test")
      RUBY

      usages = collect_usages(source, target_class: "Academico::Aluno::Email")
      expect(usages).to be_empty
    end

    it "resolve implicit hash values" do
      source = <<~RUBY
        def process
          nome = build_nome
          Foo.new(nome:)
        end
      RUBY

      usages = collect_usages(source,
        target_class: "Foo",
        method_return_types: { "build_nome" => "String" })
      expect(usages.first["nome"]).to eq("String")
    end
  end

  # ─── extract_constant_path ──────────────────────────────────────

  describe ".extract_constant_path" do
    def extract(source)
      result = Prism.parse(source)
      node = result.value.statements.body.first
      RbsUsageAnalyzer.extract_constant_path(node)
    end

    it "extrai constante simples" do
      expect(extract("Foo")).to eq("Foo")
    end

    it "extrai constant path" do
      expect(extract("Foo::Bar::Baz")).to eq("Foo::Bar::Baz")
    end

    it "extrai constant path com :: prefix" do
      expect(extract("::Shared::Cpf")).to eq("::Shared::Cpf")
    end
  end

  # ─── merge_argument_types ───────────────────────────────────────

  describe RbsUsageAnalyzer::TypeMerger do
    let(:merger) { described_class.new(target_file: nil) }

    it "prioriza tipos resolvidos sobre untyped" do
      usages = [
        { "nome" => "String", "email" => "untyped" },
        { "nome" => "String", "email" => "String" },
      ]

      result = merger.merge_argument_types(usages)
      expect(result["nome"]).to eq("String")
      expect(result["email"]).to eq("String")
    end

    it "gera union type quando há tipos diferentes" do
      usages = [
        { "value" => "String" },
        { "value" => "Integer" },
      ]

      result = merger.merge_argument_types(usages)
      expect(result["value"]).to eq("(String | Integer)")
    end

    it "normaliza :: prefix e deduplica" do
      usages = [
        { "cpf" => "::Shared::Cpf" },
        { "cpf" => "Shared::Cpf" },
      ]

      result = merger.merge_argument_types(usages)
      expect(result["cpf"]).to eq("Shared::Cpf")
    end
  end

  # ─── MethodTypeResolver ─────────────────────────────────────────

  describe RbsUsageAnalyzer::MethodTypeResolver do
    it "resolve tipo de método anotado com #:" do
      files = {
        "foo.rb" => <<~RUBY
          class Foo
            #: -> String
            def name
              "hello"
            end
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        resolver = described_class.new(paths)
        expect(resolver.resolve("Foo", "name")).to eq("String")
      end
    end

    it "resolve attr_reader anotado" do
      files = {
        "foo.rb" => <<~RUBY
          class Foo
            attr_reader :count #: Integer
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        resolver = described_class.new(paths)
        expect(resolver.resolve("Foo", "count")).to eq("Integer")
      end
    end

    it "resolve keyword defaults do initialize" do
      files = {
        "foo.rb" => <<~RUBY
          class Foo
            attr_accessor :repo

            def initialize(repo: DefaultRepo.new)
              self.repo = repo
            end
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        resolver = described_class.new(paths)
        expect(resolver.resolve("Foo", "repo")).to eq("DefaultRepo")
      end
    end

    it "resolve attrs via self.attr = Klass.new(...)" do
      files = {
        "my_app/foo.rb" => <<~RUBY
          module MyApp
            class Foo
              attr_reader :widget

              def initialize(name:)
                self.widget = Widget.new(value: name)
              end

              private

              attr_writer :widget
            end
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        resolver = described_class.new(paths)
        expect(resolver.resolve("MyApp::Foo", "widget")).to eq("Widget")
      end
    end

    it "infere attrs via call-sites quando sem anotação" do
      entity_src = <<~RUBY
        module MyApp
          class Entity
            attr_reader :nome

            def initialize(nome:)
              self.nome = nome
            end

            private

            attr_writer :nome
          end
        end
      RUBY
      service_src = <<~RUBY
        module MyApp
          class Service
            def call
              MyApp::Entity.new(nome: "test")
            end
          end
        end
      RUBY

      with_temp_files("my_app/entity.rb" => entity_src, "my_app/service.rb" => service_src) do |dir, paths|
        resolver = described_class.new(paths)
        expect(resolver.resolve("MyApp::Entity", "nome")).to eq("String")
      end
    end

    it "resolve_init_param_types retorna tipos dos parâmetros (não dos attrs)" do
      entity_src = <<~RUBY
        module MyApp
          class Entity
            attr_reader :email

            def initialize(email:)
              self.email = Wrapper.new(value: email)
            end

            private

            attr_writer :email
          end
        end
      RUBY
      caller_src = <<~RUBY
        module MyApp
          class Caller
            def call
              MyApp::Entity.new(email: "test@email.com")
            end
          end
        end
      RUBY

      with_temp_files("my_app/entity.rb" => entity_src, "my_app/caller.rb" => caller_src) do |dir, paths|
        resolver = described_class.new(paths)
        expect(resolver.resolve("MyApp::Entity", "email")).to eq("Wrapper")
        expect(resolver.resolve_init_param_types("MyApp::Entity")["email"]).to eq("String")
      end
    end
  end

  # ─── generate_rbs (integração com arquivos temporários) ─────────

  describe "#generate_rbs" do
    it "gera RBS com attrs tipados via anotação inline" do
      files = {
        "foo.rb" => <<~RUBY
          class Foo
            attr_reader :nome #: String
            attr_reader :idade #: Integer

            def initialize(nome:, idade:)
              self.nome = nome
              self.idade = idade
            end

            private

            attr_writer :nome, :idade
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        analyzer = described_class.new(target_file: paths.first, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("attr_reader nome: String")
        expect(rbs).to include("attr_reader idade: Integer")
      end
    end

    it "infere tipos do initialize via call-sites" do
      entity_src = <<~RUBY
        class Entity
          attr_reader :nome

          def initialize(nome:)
            self.nome = nome
          end

          private

          attr_writer :nome
        end
      RUBY
      service_src = <<~RUBY
        class Service
          def call
            Entity.new(nome: "Felipe")
          end
        end
      RUBY

      with_temp_files("entity.rb" => entity_src, "service.rb" => service_src) do |dir, paths|
        entity = paths.find { |p| p.end_with?("entity.rb") }
        analyzer = described_class.new(target_file: entity, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("nome: String")
        expect(rbs).to include("def initialize: (nome: String) -> void")
      end
    end

    it "marca parâmetros opcionais com ? prefix" do
      entity_src = <<~RUBY
        class Entity
          attr_reader :nome, :senha

          def initialize(nome:, senha: nil)
            self.nome = nome
            self.senha = senha
          end

          private

          attr_writer :nome, :senha
        end
      RUBY
      caller_src = <<~RUBY
        class Caller
          def call
            Entity.new(nome: "Felipe", senha: "secret")
          end
        end
      RUBY

      with_temp_files("entity.rb" => entity_src, "caller.rb" => caller_src) do |dir, paths|
        entity = paths.find { |p| p.end_with?("entity.rb") }
        analyzer = described_class.new(target_file: entity, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("nome: String")
        expect(rbs).to include("?senha: String")
        expect(rbs).not_to include("?nome:")
      end
    end

    it "infere tipo de attr via self.attr = Klass.new(...)" do
      files = {
        "entity.rb" => <<~RUBY
          class Entity
            attr_reader :email

            def initialize(email_str:)
              self.email = Email.new(endereco: email_str)
            end

            private

            attr_writer :email
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        analyzer = described_class.new(target_file: paths.first, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("attr_reader email: Email")
      end
    end

    it "gera módulos aninhados corretamente" do
      email_src = <<~RUBY
        module Academico
          module Aluno
            class Email
              attr_accessor :endereco

              def initialize(endereco:)
                self.endereco = endereco
              end
            end
          end
        end
      RUBY
      caller_src = <<~RUBY
        class Caller
          def call
            Academico::Aluno::Email.new(endereco: "test@email.com")
          end
        end
      RUBY

      with_temp_files("foo.rb" => email_src, "caller.rb" => caller_src) do |dir, paths|
        email_file = paths.find { |p| p.end_with?("foo.rb") }
        analyzer = described_class.new(target_file: email_file, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("module Academico")
        expect(rbs).to include("  module Aluno")
        expect(rbs).to include("    class Email")
        expect(rbs).to include("      attr_accessor endereco: String")
      end
    end

    it "preserva superclass na saída" do
      files = {
        "controller.rb" => <<~RUBY
          class MyController < ApplicationController
            def index
            end
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        analyzer = described_class.new(target_file: paths.first, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("class MyController < ApplicationController")
      end
    end

    it "gera void para actions de controllers" do
      files = {
        "controller.rb" => <<~RUBY
          class MyController < ApplicationController
            def create
              redirect_to root_path
            end

            def show
              render json: {}
            end
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        analyzer = described_class.new(target_file: paths.first, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("def create: () -> void")
        expect(rbs).to include("def show: () -> void")
      end
    end

    it "gera seção private quando há membros privados" do
      files = {
        "foo.rb" => <<~RUBY
          class Foo
            def call; end

            private

            attr_accessor :data
          end
        RUBY
      }

      with_temp_files(files) do |dir, paths|
        analyzer = described_class.new(target_file: paths.first, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("private")
        expect(rbs).to include("attr_accessor data:")
      end
    end

    it "resolve tipos inter-procedurais via method chain (receiver.method)" do
      dto_src = <<~RUBY
        class Dto
          #: -> String
          def cpf!
            cpf || raise
          end

          #: -> String
          def nome!
            nome || raise
          end
        end
      RUBY
      entity_src = <<~RUBY
        class Entity
          attr_reader :nome, :cpf

          def initialize(nome:, cpf:)
            self.nome = nome
            self.cpf = cpf
          end

          private

          attr_writer :nome, :cpf
        end
      RUBY
      service_src = <<~RUBY
        class Service
          attr_accessor :aluno_dto #: Dto

          def call
            dto = aluno_dto
            Entity.new(nome: dto.nome!, cpf: dto.cpf!)
          end
        end
      RUBY

      with_temp_files("dto.rb" => dto_src, "entity.rb" => entity_src, "service.rb" => service_src) do |dir, paths|
        entity = paths.find { |p| p.end_with?("entity.rb") }
        analyzer = described_class.new(target_file: entity, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("nome: String")
        expect(rbs).to include("cpf: String")
      end
    end

    it "resolve tipo de param cross-class via call-site (Email.endereco = String)" do
      entity_src = <<~RUBY
        module MyApp
          class Entity
            attr_reader :email

            def initialize(email:)
              self.email = Email.new(endereco: email)
            end

            private

            attr_writer :email
          end
        end
      RUBY
      email_src = <<~RUBY
        module MyApp
          class Email
            attr_accessor :endereco

            def initialize(endereco:)
              self.endereco = endereco
            end
          end
        end
      RUBY
      caller_src = <<~RUBY
        class Caller
          def call
            MyApp::Entity.new(email: "test@email.com")
          end
        end
      RUBY

      with_temp_files("entity.rb" => entity_src, "email.rb" => email_src, "caller.rb" => caller_src) do |dir, paths|
        email = paths.find { |p| p.end_with?("email.rb") }
        analyzer = described_class.new(target_file: email, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("endereco: String")
      end
    end

    it "resolve return type de método que retorna attr conhecido (to_s -> endereco)" do
      email_src = <<~RUBY
        module MyApp
          class Email
            attr_accessor :endereco

            def initialize(endereco:)
              self.endereco = endereco
            end

            def to_s
              endereco
            end
          end
        end
      RUBY
      caller_src = <<~RUBY
        class Caller
          def call
            MyApp::Email.new(endereco: "test@email.com")
          end
        end
      RUBY

      with_temp_files("email.rb" => email_src, "caller.rb" => caller_src) do |dir, paths|
        email = paths.find { |p| p.end_with?("email.rb") }
        analyzer = described_class.new(target_file: email, source_files: paths)
        rbs = analyzer.generate_rbs

        expect(rbs).to include("def to_s: () -> String")
        expect(rbs).not_to include("def to_s: () -> untyped")
      end
    end
  end

  # ─── Integração com arquivos reais do projeto ───────────────────

  describe "#generate_rbs (integração com arquivos reais)", :integration do
    let(:source_files) { Dir["engines/**/*.rb", "app/**/*.rb"] }

    context "Academico::Aluno::Entity" do
      let(:target_file) { "engines/academico/app/domains/academico/aluno/entity.rb" }

      it "gera RBS correto" do
        analyzer = described_class.new(target_file: target_file, source_files: source_files)
        rbs = analyzer.generate_rbs

        aggregate_failures do
          expect(rbs).to include("module Academico")
          expect(rbs).to include("class Entity")
          expect(rbs).to include("nome: String")
          expect(rbs).to include("email: Email")
          expect(rbs).to include("cpf: ::Shared::Cpf")
          expect(rbs).to match(/\?senha: String\?/)
          expect(rbs).to include("private")
        end
      end
    end

    context "Academico::Aluno::Email" do
      let(:target_file) { "engines/academico/app/domains/academico/aluno/email.rb" }

      it "infere endereco como String via cross-class analysis" do
        analyzer = described_class.new(target_file: target_file, source_files: source_files)
        rbs = analyzer.generate_rbs

        aggregate_failures do
          expect(rbs).to include("module Academico")
          expect(rbs).to include("module Aluno")
          expect(rbs).to include("class Email")
          expect(rbs).to include("endereco: String")
          expect(rbs).to include("def to_s: () -> String")
        end
      end
    end

    context "Academico::Aluno::Matricular" do
      let(:target_file) { "engines/academico/app/usecases/academico/aluno/matricular.rb" }

      it "infere tipos de attrs sem anotação via call-sites" do
        analyzer = described_class.new(target_file: target_file, source_files: source_files)
        rbs = analyzer.generate_rbs

        aggregate_failures do
          expect(rbs).to include("class Matricular")
          expect(rbs).to include("errors: ActiveModel::Errors")
          expect(rbs).to include("def call: -> void")
          expect(rbs).to include("aluno_dto: Academico::Aluno::Matricular::Dto")
          expect(rbs).to match(/aluno_repository:.*Impl/)
        end
      end
    end

    context "Finance::Client::Enroll" do
      let(:target_file) { "engines/finance/app/models/finance/client/enroll.rb" }

      it "infere attrs client e card via call-sites" do
        analyzer = described_class.new(target_file: target_file, source_files: source_files)
        rbs = analyzer.generate_rbs

        aggregate_failures do
          expect(rbs).to include("class Enroll")
          expect(rbs).to include("client: Finance::Client::Entity")
          expect(rbs).to include("card: Finance::Card::Entity")
        end
      end
    end

    context "Finance::ClientsController" do
      let(:target_file) { "engines/finance/app/controllers/finance/clients_controller.rb" }

      it "gera void para actions e infere return types de helpers" do
        analyzer = described_class.new(target_file: target_file, source_files: source_files)
        rbs = analyzer.generate_rbs

        aggregate_failures do
          expect(rbs).to include("class ClientsController < ApplicationController")
          expect(rbs).to include("def create: () -> void")
          expect(rbs).to include("build_client: () -> Finance::Client::Entity")
          expect(rbs).to include("build_card: () -> Finance::Card::Entity")
        end
      end
    end

    context "Marketing::LeadsController" do
      let(:target_file) { "engines/marketing/app/controllers/marketing/leads_controller.rb" }

      it "infere tipo de attr lead" do
        analyzer = described_class.new(target_file: target_file, source_files: source_files)
        rbs = analyzer.generate_rbs

        aggregate_failures do
          expect(rbs).to include("class LeadsController < ApplicationController")
          expect(rbs).to include("lead: Marketing::Lead::Entity")
        end
      end
    end
  end
end
