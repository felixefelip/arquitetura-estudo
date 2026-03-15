class RbsUsageAnalyzer
  class RbsBuilder
    def initialize(target_class:, superclass_name:)
      @target_class = target_class
      @superclass_name = superclass_name
    end

    def build(members, init_arg_types, attr_types, optional_params = Set.new, method_param_types = {})
      parts = @target_class.split("::")
      class_name = parts.pop
      modules = parts

      base_indent = "  " * modules.size
      member_indent = base_indent + "  "

      lines = []
      modules.each_with_index do |mod, i|
        lines << "#{"  " * i}module #{mod}"
      end
      lines << "#{base_indent}class #{class_name}#{@superclass_name ? " < #{@superclass_name}" : ""}"

      current_visibility = :public
      has_private = members.any? { |m| m.visibility == :private }
      has_protected = members.any? { |m| m.visibility == :protected }

      # Agrupar por visibilidade: public -> protected -> private
      [:public, :protected, :private].each do |vis|
        vis_members = members.select { |m| m.visibility == vis }
        next if vis_members.empty?

        if vis != :public
          lines << ""
          lines << "#{member_indent}#{vis}"
          lines << ""
        end

        vis_members.each do |member|
          case member.kind
          when :method
            sig = member.signature
            # Substituir initialize com tipos inferidos dos call-sites
            if member.name == "initialize" && !init_arg_types.empty?
              sig_args = init_arg_types.map { |name, type|
                prefix = optional_params.include?(name) ? "?" : ""
                "#{prefix}#{name}: #{type}"
              }.join(", ")
              sig = "initialize: (#{sig_args}) -> void"
            elsif method_param_types[member.name]
              sig = apply_inferred_param_types(sig, method_param_types[member.name])
            end
            lines << "#{member_indent}def #{sig}"
          when :attr_accessor, :attr_reader, :attr_writer
            sig = member.signature
            # Se o attr está untyped, tentar preencher via inferência do initialize
            if sig.end_with?(": untyped") && attr_types[member.name]
              sig = "#{member.name}: #{attr_types[member.name]}"
            end
            prefix = member.kind.to_s.sub("_", "_")
            lines << "#{member_indent}#{member.kind} #{sig}"
          end
        end
      end

      lines << "#{base_indent}end"
      modules.each_with_index do |_, i|
        lines << "#{"  " * (modules.size - 1 - i)}end"
      end

      lines.join("\n")
    end

    private

    # Substitui parâmetros `untyped` na assinatura por tipos inferidos
    # Ex: "publicar_evento: (aluno: untyped) -> untyped" com {aluno: "Entity"}
    #   → "publicar_evento: (aluno: Entity) -> untyped"
    def apply_inferred_param_types(signature, param_types)
      param_types.each do |param_name, type|
        signature = signature.gsub(/(\??)#{Regexp.escape(param_name)}:\s*untyped/, "\\1#{param_name}: #{type}")
      end
      signature
    end
  end
end
