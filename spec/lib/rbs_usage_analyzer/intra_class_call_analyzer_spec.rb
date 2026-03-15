require "spec_helper"
require "rbs_usage_analyzer"

RSpec.describe RbsUsageAnalyzer::IntraClassCallAnalyzer do
  def analyze(source, attr_types: {}, method_type_resolver: nil)
    result = Prism.parse(source)
    visitor = described_class.new(attr_types: attr_types, method_type_resolver: method_type_resolver)
    result.value.accept(visitor)
    visitor
  end

  it "infere tipo de kwarg via local variable = Klass.new(...)" do
    source = <<~RUBY
      class Foo
        def call
          aluno = Entity.new(nome: "test")
          publicar(aluno:)
        end

        def publicar(aluno:)
        end
      end
    RUBY

    visitor = analyze(source)
    expect(visitor.inferred_param_types["publicar"]["aluno"]).to eq("Entity")
  end

  it "infere tipo via ImplicitNode (shorthand keyword: publicar(aluno:))" do
    source = <<~RUBY
      class Foo
        def call
          aluno = ::MyApp::Entity.new(nome: "test")
          publicar(aluno:)
        end
      end
    RUBY

    visitor = analyze(source)
    expect(visitor.inferred_param_types["publicar"]["aluno"]).to eq("::MyApp::Entity")
  end

  it "ignora argumentos com tipo desconhecido" do
    source = <<~RUBY
      class Foo
        def call
          publicar(aluno: alguma_coisa)
        end
      end
    RUBY

    visitor = analyze(source)
    expect(visitor.inferred_param_types["publicar"]).to be_empty
  end

  it "infere múltiplos kwargs na mesma chamada" do
    source = <<~RUBY
      class Foo
        def call
          aluno = Entity.new
          curso = Curso.new
          matricular(aluno:, curso:)
        end
      end
    RUBY

    visitor = analyze(source)
    expect(visitor.inferred_param_types["matricular"]["aluno"]).to eq("Entity")
    expect(visitor.inferred_param_types["matricular"]["curso"]).to eq("Curso")
  end
end
