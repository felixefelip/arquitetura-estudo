require "prism"

# Analisador que gera RBS completo de uma classe Ruby, combinando:
# - Anotações rbs-inline existentes (#: e @rbs)
# - Inferência de tipos do initialize via análise dos call-sites (quem chama .new)
# - Tipos de attr_accessor/reader/writer via anotações inline
#
# Uso:
#   analyzer = RbsUsageAnalyzer.new(
#     target_class: "Finance::Client::Enroll",
#     target_file: "engines/finance/app/models/finance/client/enroll.rb",
#     source_files: Dir["engines/**/*.rb", "app/**/*.rb"]
#   )
#   puts analyzer.generate_rbs
#
class RbsUsageAnalyzer
  attr_reader :target_class, :target_file, :source_files

  def initialize(target_class: nil, source_files:, target_file: nil)
    @source_files = source_files
    @target_file = target_file
    @target_class = target_class

    if @target_file && !@target_class
      @target_class = extract_class_name_from_file(@target_file)
    elsif @target_class && !@target_file
      @target_file = find_target_file
    end
  end

  def generate_rbs
    return nil unless @target_file && File.exist?(@target_file)

    # Parsear o arquivo-alvo para extrair todos os membros da classe
    target_members = parse_target_class

    # Inferir tipos do initialize via call-sites
    init_arg_types = infer_initialize_types

    # Inferir tipos dos attrs a partir do initialize (self.x = param)
    attr_types = infer_attr_types_from_initialize(init_arg_types)

    # Inferir tipos dos attrs a partir de todos os métodos da classe
    # (self.x = Foo.new ou variável local com mesmo nome do attr)
    attr_types_from_class = infer_attr_types_from_class_body(target_members)
    attr_types_from_class.each do |name, type|
      attr_types[name] ||= type
    end

    # Enriquecer init_arg_types com tipos inferidos (defaults, attrs)
    attr_types.each do |attr_name, type|
      if init_arg_types[attr_name] == "untyped"
        init_arg_types[attr_name] = type
      end
    end

    # Resolver return types de métodos que retornam attrs conhecidos
    resolve_method_return_types_from_attrs(target_members, attr_types)

    # Identificar parâmetros opcionais do initialize
    optional_params = extract_optional_init_params

    build_full_rbs(target_members, init_arg_types, attr_types, optional_params)
  end

  def self.extract_constant_path(node)
    case node
    when Prism::ConstantPathNode
      parts = []
      current = node
      while current.is_a?(Prism::ConstantPathNode)
        parts.unshift(current.name.to_s)
        current = current.parent
      end
      if current.is_a?(Prism::ConstantReadNode)
        parts.unshift(current.name.to_s)
      elsif current.nil?
        parts.unshift("")
      end
      parts.join("::")
    when Prism::ConstantReadNode
      node.name.to_s
    else
      nil
    end
  end

  private

  # ─── Extrair nomes dos keyword params opcionais do initialize ─────

  def extract_optional_init_params
    return Set.new unless @target_file && File.exist?(@target_file)

    source = File.read(@target_file)
    result = Prism.parse(source)
    visitor = OptionalParamExtractor.new
    result.value.accept(visitor)
    visitor.optional_params
  end

  # ─── Localizar arquivo da classe-alvo ──────────────────────────────

  def find_target_file
    class_path = @target_class.gsub("::", "/").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    @source_files.find { |f| f.end_with?("#{class_path}.rb") }
  end

  # ─── Extrair nome da classe a partir do arquivo (via Prism) ────────

  def extract_class_name_from_file(file)
    return nil unless File.exist?(file)

    result = Prism.parse(File.read(file))
    visitor = ClassNameExtractor.new
    result.value.accept(visitor)
    visitor.class_name
  end

  # ─── Parsear classe-alvo: métodos, attrs, visibilidade ─────────────

  def parse_target_class
    source = File.read(@target_file)
    result = Prism.parse(source)
    comments = result.comments
    lines = source.lines

    visitor = ClassMemberCollector.new(comments: comments, lines: lines)
    result.value.accept(visitor)
    @superclass_name = visitor.superclass_name
    visitor.members
  end

  # ─── Inferir tipos dos attrs via initialize ────────────────────────
  # Analisa o corpo do initialize para encontrar `self.x = param` e
  # mapeia o tipo do attr a partir do tipo do parâmetro (inferido via call-sites)
  # ou do valor default do keyword argument.

  def infer_attr_types_from_initialize(init_arg_types)
    return {} unless @target_file && File.exist?(@target_file)

    source = File.read(@target_file)
    result = Prism.parse(source)

    visitor = InitializeBodyAnalyzer.new
    result.value.accept(visitor)

    attr_types = {}

    # Mapear defaults dos keyword params: param_name -> tipo do default
    default_types = visitor.keyword_defaults

    # Mapear self.attr = expr encontrados no initialize
    visitor.self_assignments.each do |attr_name, expr_info|
      type = case expr_info[:kind]
             when :param
               # self.x = x → tipo vem dos call-sites ou do default
               param_name = expr_info[:name]
               call_site_type = init_arg_types[param_name]
               call_site_type = nil if call_site_type == "untyped"
               call_site_type || default_types[param_name]
             when :call
               # self.x = algo.method → tentar resolver
               expr_info[:type]
             when :constant
               expr_info[:type]
             end

      attr_types[attr_name] = type if type
    end

    attr_types
  end

  # ─── Inferir tipos dos attrs via corpo de todos os métodos ─────────
  # Procura `self.attr = Foo.new(...)` em qualquer método da classe
  # e variáveis locais com mesmo nome de um attr_accessor.

  def infer_attr_types_from_class_body(members)
    return {} unless @target_file && File.exist?(@target_file)

    attr_names = members.select { |m| [:attr_accessor, :attr_reader, :attr_writer].include?(m.kind) }
                        .map(&:name)
                        .to_set
    return {} if attr_names.empty?

    source = File.read(@target_file)
    result = Prism.parse(source)

    visitor = ClassBodyAttrAnalyzer.new(attr_names: attr_names)
    result.value.accept(visitor)

    visitor.attr_types
  end

  # ─── Inferir tipos do initialize via call-sites ────────────────────

  def infer_initialize_types
    usages = find_new_calls
    return {} if usages.empty?
    merge_argument_types(usages)
  end

  def find_new_calls
    @source_files.flat_map { |file| analyze_caller_file(file) }
  end

  def analyze_caller_file(file)
    source = File.read(file)
    result = Prism.parse(source)
    comments = result.comments
    method_return_types = extract_method_return_types(source, comments, result.value)

    # Incluir tipos de attr_reader/attr_accessor como retorno de métodos
    # (em Ruby, attr_reader :foo gera um método foo)
    extract_attr_return_types(source, comments, result.value).each do |name, type|
      method_return_types[name] ||= type
    end

    # Resolver tipos do caller class via MethodTypeResolver
    # (infere attrs sem anotação via keyword defaults e call-sites)
    caller_visitor = ClassNameExtractor.new
    result.value.accept(caller_visitor)
    if caller_visitor.class_name
      caller_types = method_type_resolver.resolve_all(caller_visitor.class_name)
      caller_types.each do |name, type|
        method_return_types[name] ||= type
      end
    end

    local_var_types = {}

    visitor = NewCallCollector.new(
      target_class: @target_class,
      method_return_types: method_return_types,
      local_var_types: local_var_types,
      method_type_resolver: method_type_resolver,
      caller_class_name: caller_visitor.class_name
    )
    result.value.accept(visitor)
    visitor.usages
  end

  def method_type_resolver
    @method_type_resolver ||= MethodTypeResolver.new(@source_files)
  end

  def extract_attr_return_types(source, comments, tree)
    types = {}
    lines = source.lines
    collector = ClassMemberCollector.new(comments: comments, lines: lines)
    tree.accept(collector)
    collector.members.each do |member|
      next unless [:attr_accessor, :attr_reader].include?(member.kind)
      if member.signature =~ /\w+:\s*(.+)/
        type = $1.strip
        types[member.name] = type unless type == "untyped"
      end
    end
    types
  end

  def extract_method_return_types(source, comments, tree)
    types = {}
    lines = source.lines

    def_visitor = DefCollector.new
    tree.accept(def_visitor)

    def_visitor.defs.each do |defn|
      def_line = defn.location.start_line
      method_name = defn.name.to_s

      return_type = find_rbs_return_type(comments, lines, def_line)
      return_type ||= infer_return_type_from_body(defn)

      types[method_name] = return_type if return_type
    end

    types
  end

  def find_rbs_return_type(comments, lines, def_line)
    comments.each do |comment|
      comment_line = comment.location.start_line
      next unless comment_line.between?(def_line - 3, def_line - 1)
      next unless lines_between_are_blank_or_comments(lines, comment_line, def_line)

      text = comment.location.slice

      # @rbs () -> ReturnType
      if text =~ /@rbs\s*\(.*?\)\s*->\s*(.+)/
        return $1.strip
      end

      # #: () -> ReturnType  ou  #: -> ReturnType
      if text =~ /#:\s*(?:\(.*?\)\s*)?->\s*(.+)/
        return $1.strip
      end
    end
    nil
  end

  def lines_between_are_blank_or_comments(lines, from_line, to_line)
    ((from_line)...(to_line - 1)).all? do |i|
      line = lines[i]
      next true if line.nil?
      stripped = line.strip
      stripped.empty? || stripped.start_with?("#")
    end
  end

  def infer_return_type_from_body(defn)
    body = defn.body
    return nil unless body

    last_stmt = case body
                when Prism::StatementsNode then body.body.last
                else body
                end

    return nil unless last_stmt

    if last_stmt.is_a?(Prism::CallNode) && last_stmt.name == :new && last_stmt.receiver
      class_name = self.class.extract_constant_path(last_stmt.receiver)
      return class_name if class_name
    end

    nil
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
    return if attr_types.empty?
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

  # ─── Gerar RBS completo ────────────────────────────────────────────

  def build_full_rbs(members, init_arg_types, attr_types, optional_params = Set.new)
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
end

require_relative "rbs_usage_analyzer/optional_param_extractor"
require_relative "rbs_usage_analyzer/class_name_extractor"
require_relative "rbs_usage_analyzer/class_body_attr_analyzer"
require_relative "rbs_usage_analyzer/initialize_body_analyzer"
require_relative "rbs_usage_analyzer/class_member_collector"
require_relative "rbs_usage_analyzer/def_collector"
require_relative "rbs_usage_analyzer/new_call_collector"
require_relative "rbs_usage_analyzer/method_type_resolver"
