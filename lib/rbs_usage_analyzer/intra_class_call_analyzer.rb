class RbsUsageAnalyzer
  # Analisa chamadas intra-classe para inferir tipos de parâmetros de métodos privados.
  # Ex: em `call`, `publicar_evento(aluno:)` onde `aluno = Entity.new(...)` →
  # infere que `publicar_evento` tem `aluno: Academico::Aluno::Entity`
  class IntraClassCallAnalyzer < Prism::Visitor
    # method_name → { param_name → type }
    attr_reader :inferred_param_types

    def initialize(attr_types: {}, method_type_resolver: nil)
      @attr_types = attr_types
      @method_type_resolver = method_type_resolver
      @inferred_param_types = Hash.new { |h, k| h[k] = {} }
      @local_var_types = {}
    end

    def visit_def_node(node)
      old_vars = @local_var_types.dup
      @local_var_types = {}
      collect_local_assignments(node)
      super
      @local_var_types = old_vars
    end

    def visit_call_node(node)
      # Chamadas sem receiver (implícito self) com keyword args
      if node.receiver.nil? && node.arguments
        method_name = node.name.to_s
        args = extract_keyword_arg_types(node)
        args.each do |param_name, type|
          next if type == "untyped"
          existing = @inferred_param_types[method_name][param_name]
          @inferred_param_types[method_name][param_name] = type unless existing
        end
      end
      super
    end

    private

    def collect_local_assignments(defn)
      body = defn.body
      return unless body

      stmts = case body
              when Prism::StatementsNode then body.body
              else [body]
              end

      stmts.each do |stmt|
        case stmt
        when Prism::LocalVariableWriteNode
          type = infer_expression_type(stmt.value)
          @local_var_types[stmt.name.to_s] = type if type
        end
      end
    end

    def infer_expression_type(node)
      case node
      when Prism::CallNode
        if node.name == :new && node.receiver
          RbsUsageAnalyzer.extract_constant_path(node.receiver)
        elsif node.receiver.nil?
          # Chamada a método sem receiver → pode ser attr ou método da classe
          @attr_types[node.name.to_s]
        elsif node.receiver.is_a?(Prism::LocalVariableReadNode)
          # var.method → resolver tipo do var, depois método
          var_type = @local_var_types[node.receiver.name.to_s]
          if var_type && @method_type_resolver
            @method_type_resolver.resolve(var_type, node.name.to_s)
          end
        end
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        RbsUsageAnalyzer.extract_constant_path(node)
      when Prism::StringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::SymbolNode then "Symbol"
      when Prism::TrueNode, Prism::FalseNode then "bool"
      end
    end

    def extract_keyword_arg_types(call_node)
      args = {}
      call_node.arguments.arguments.each do |arg|
        case arg
        when Prism::KeywordHashNode
          arg.elements.each do |elem|
            next unless elem.is_a?(Prism::AssocNode)
            key = extract_symbol_key(elem.key)
            next unless key
            type = resolve_value_type(elem.value)
            args[key] = type if type
          end
        end
      end
      args
    end

    def extract_symbol_key(node)
      return node.unescaped if node.is_a?(Prism::SymbolNode)
      nil
    end

    def resolve_value_type(node)
      case node
      when Prism::LocalVariableReadNode
        @local_var_types[node.name.to_s] || "untyped"
      when Prism::ImplicitNode
        resolve_value_type(node.value)
      when Prism::CallNode
        infer_expression_type(node) || "untyped"
      when Prism::StringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::SymbolNode then "Symbol"
      when Prism::TrueNode, Prism::FalseNode then "bool"
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        RbsUsageAnalyzer.extract_constant_path(node) || "untyped"
      else
        "untyped"
      end
    end
  end
end
