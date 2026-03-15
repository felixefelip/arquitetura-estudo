class RbsUsageAnalyzer
  class ClassBodyAttrAnalyzer < Prism::Visitor
    attr_reader :attr_types, :collection_element_types

    def initialize(attr_names:)
      @attr_names = attr_names
      @attr_types = {}
      @collection_element_types = {}
      @in_method = false
    end

    def visit_def_node(node)
      @in_method = true
      @current_local_types = {}
      super
      # Após visitar o método, verificar variáveis locais que batem com attrs
      @current_local_types.each do |name, type|
        if @attr_names.include?(name) && !@attr_types[name]
          @attr_types[name] = type
        end
      end
      @in_method = false
    end

    def visit_call_node(node)
      if @in_method
        # self.attr = Foo.new(...)
        if node.name.to_s.end_with?("=") && node.receiver.is_a?(Prism::SelfNode)
          attr_name = node.name.to_s.chomp("=")
          if @attr_names.include?(attr_name)
            value = node.arguments&.arguments&.first
            type = infer_type_from_node(value) if value
            @attr_types[attr_name] = type if type && !@attr_types[attr_name]
          end
        end

        # attr << Foo.new(...) — infer element type for collection attrs
        if node.name == :<<
          attr_name = receiver_attr_name(node.receiver)
          if attr_name && @attr_names.include?(attr_name)
            value = node.arguments&.arguments&.first
            type = infer_type_from_node(value) if value
            if type
              (@collection_element_types[attr_name] ||= Set.new) << type
            end
          end
        end
      end
      super
    end

    def visit_local_variable_write_node(node)
      if @in_method
        name = node.name.to_s
        if @attr_names.include?(name)
          type = infer_type_from_node(node.value)
          @current_local_types[name] = type if type
        end
      end
      super
    end

    private

    # Extracts the attr name from the receiver of a << call.
    # Handles: telefones << ... (implicit self) and self.telefones << ...
    def receiver_attr_name(receiver)
      case receiver
      when Prism::CallNode
        if receiver.receiver.nil? || receiver.receiver.is_a?(Prism::SelfNode)
          receiver.name.to_s
        end
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
      end
    end
  end
end
