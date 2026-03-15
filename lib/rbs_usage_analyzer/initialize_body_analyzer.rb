class RbsUsageAnalyzer
  class InitializeBodyAnalyzer < Prism::Visitor
    attr_reader :self_assignments, :keyword_defaults

    def initialize
      @self_assignments = {}
      @keyword_defaults = {}
      @param_names = []
      @in_initialize = false
    end

    def visit_def_node(node)
      return super unless node.name == :initialize

      @in_initialize = true
      @param_names = extract_param_names(node.parameters)
      extract_keyword_defaults(node.parameters)
      super
      @in_initialize = false
    end

    def visit_call_node(node)
      if @in_initialize && node.name.to_s.end_with?("=") && node.receiver.is_a?(Prism::SelfNode)
        attr_name = node.name.to_s.chomp("=")
        value = node.arguments&.arguments&.first
        if value
          @self_assignments[attr_name] = resolve_assignment_value(value)
        end
      end
      super
    end

    private

    def extract_param_names(params)
      return [] unless params
      names = []
      params.keywords.each do |kw|
        names << kw.name.to_s
      end if params.respond_to?(:keywords)
      params.requireds.each do |p|
        names << p.name.to_s if p.respond_to?(:name)
      end if params.respond_to?(:requireds)
      names
    end

    def extract_keyword_defaults(params)
      return unless params&.respond_to?(:keywords)

      params.keywords.each do |kw|
        next unless kw.is_a?(Prism::OptionalKeywordParameterNode)
        param_name = kw.name.to_s
        default_type = infer_type_from_node(kw.value)
        @keyword_defaults[param_name] = default_type if default_type
      end
    end

    def resolve_assignment_value(node)
      case node
      when Prism::LocalVariableReadNode
        name = node.name.to_s
        if @param_names.include?(name)
          { kind: :param, name: name }
        else
          { kind: :unknown }
        end
      when Prism::CallNode
        if node.receiver.is_a?(Prism::LocalVariableReadNode)
          # aluno_dto.errors → tipo depende do que aluno_dto retorna
          { kind: :call, type: nil }
        elsif node.name == :new && node.receiver
          class_name = RbsUsageAnalyzer.extract_constant_path(node.receiver)
          { kind: :constant, type: class_name }
        else
          { kind: :unknown }
        end
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        { kind: :constant, type: RbsUsageAnalyzer.extract_constant_path(node) }
      else
        { kind: :unknown }
      end
    end

    def infer_type_from_node(node)
      case node
      when Prism::CallNode
        if node.name == :new && node.receiver
          RbsUsageAnalyzer.extract_constant_path(node.receiver)
        end
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        RbsUsageAnalyzer.extract_constant_path(node)
      when Prism::StringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::SymbolNode then "Symbol"
      when Prism::TrueNode, Prism::FalseNode then "bool"
      # NilNode ignorado: default nil indica parâmetro opcional, não tipo nil
      end
    end
  end
end
