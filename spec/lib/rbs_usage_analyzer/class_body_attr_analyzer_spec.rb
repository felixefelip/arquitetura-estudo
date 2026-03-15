require "spec_helper"
require "rbs_usage_analyzer"

RSpec.describe RbsUsageAnalyzer::ClassBodyAttrAnalyzer do
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
