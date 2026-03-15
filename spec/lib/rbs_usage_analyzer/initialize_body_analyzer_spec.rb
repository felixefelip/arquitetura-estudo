require "spec_helper"
require "rbs_usage_analyzer"

RSpec.describe RbsUsageAnalyzer::InitializeBodyAnalyzer do
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

  it "detecta self.attr = param.method como :param_method" do
    source = <<~RUBY
      class Matricular
        def initialize(aluno_dto:)
          self.errors = aluno_dto.errors
        end
      end
    RUBY

    visitor = analyze(source)
    expect(visitor.self_assignments["errors"][:kind]).to eq(:param_method)
    expect(visitor.self_assignments["errors"][:param_name]).to eq("aluno_dto")
    expect(visitor.self_assignments["errors"][:method_name]).to eq("errors")
  end
end
