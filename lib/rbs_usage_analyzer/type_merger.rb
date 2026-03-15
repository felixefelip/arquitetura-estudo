class RbsUsageAnalyzer
  class TypeMerger
    def initialize(target_file:)
      @target_file = target_file
    end

    # ─── Unificar tipos de múltiplos call-sites ────────────────────────

    def merge_argument_types(usages)
      all_types = Hash.new { |h, k| h[k] = [] }

      usages.each do |usage|
        usage.each do |arg_name, type|
          all_types[arg_name] << type
        end
      end

      merged = {}
      all_types.each do |arg_name, types|
        # Preferir tipos resolvidos sobre untyped
        resolved = types.reject { |t| t == "untyped" }
        resolved = types if resolved.empty?

        # Normalizar :: prefix e deduplicar
        unique = resolved.map { |t| t.sub(/\A::/, "") }.uniq
        merged[arg_name] = unique.size == 1 ? unique.first : "(#{unique.join(" | ")})"
      end

      merged
    end

    # ─── Resolver return types de métodos que retornam attrs ────────
    # Após inferir attr_types, re-examina métodos com return "untyped"
    # e substitui pelo tipo do attr se a última expressão do método
    # for uma chamada implícita a um attr conhecido.

    def resolve_method_return_types_from_attrs(members, attr_types)
      return unless @target_file && File.exist?(@target_file)

      source = File.read(@target_file)
      result = Prism.parse(source)

      # Coletar mapeamento: method_name -> última expressão do body
      method_last_exprs = {}
      collector = DefCollector.new
      result.value.accept(collector)

      collector.defs.each do |defn|
        body = defn.body
        next unless body

        last_stmt = case body
                    when Prism::StatementsNode then body.body.last
                    else body
                    end
        next unless last_stmt

        # Chamada implícita a self (ex: `endereco` sem receiver)
        if last_stmt.is_a?(Prism::CallNode) && last_stmt.receiver.nil? && last_stmt.arguments.nil?
          method_last_exprs[defn.name.to_s] = last_stmt.name.to_s
        end

        # Literal na última expressão → return type direto
        literal_type = infer_literal_type(last_stmt)
        if literal_type
          members.each do |m|
            next unless m.kind == :method && m.name == defn.name.to_s
            next unless m.signature.end_with?("-> untyped")
            m.signature = m.signature.sub("-> untyped", "-> #{literal_type}")
          end
        end
      end

      # Atualizar signatures de métodos que retornam attrs
      members.each do |member|
        next unless member.kind == :method
        next unless member.signature.end_with?("-> untyped")

        attr_name = method_last_exprs[member.name]
        next unless attr_name

        resolved_type = attr_types[attr_name]
        next unless resolved_type

        member.signature = member.signature.sub("-> untyped", "-> #{resolved_type}")
      end
    end

    private

    def infer_literal_type(node)
      case node
      when Prism::StringNode, Prism::InterpolatedStringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::FloatNode then "Float"
      when Prism::SymbolNode, Prism::InterpolatedSymbolNode then "Symbol"
      when Prism::TrueNode, Prism::FalseNode then "bool"
      when Prism::NilNode then "nil"
      when Prism::ArrayNode then "Array[untyped]"
      when Prism::HashNode then "Hash[untyped, untyped]"
      when Prism::InterpolatedRegularExpressionNode, Prism::RegularExpressionNode then "Regexp"
      end
    end
  end
end
