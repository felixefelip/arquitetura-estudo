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
    type_merger.resolve_method_return_types_from_attrs(target_members, attr_types)

    # Inferir tipos de parâmetros de métodos via chamadas intra-classe
    method_param_types = infer_method_param_types(attr_types)

    # Identificar parâmetros opcionais do initialize
    optional_params = extract_optional_init_params

    namespace_classes = resolve_namespace_classes
    rbs_builder = RbsBuilder.new(target_class: @target_class, superclass_name: @superclass_name, namespace_classes: namespace_classes)
    rbs_builder.build(target_members, init_arg_types, attr_types, optional_params, method_param_types)
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
             when :param_method
               # self.x = param.method → resolver tipo do param, depois método
               param_name = expr_info[:param_name]
               param_type = init_arg_types[param_name]
               param_type = nil if param_type.nil? || param_type == "untyped"
               if param_type
                 method_type_resolver.resolve(param_type, expr_info[:method_name])
               end
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
    type_merger.merge_argument_types(usages)
  end

  def find_new_calls
    analyzer = CallerFileAnalyzer.new(target_class: @target_class, method_type_resolver: method_type_resolver)
    @source_files.flat_map { |file| analyzer.analyze(file) }
  end

  def method_type_resolver
    @method_type_resolver ||= MethodTypeResolver.new(@source_files)
  end

  def type_merger
    @type_merger ||= TypeMerger.new(target_file: @target_file)
  end

  # ─── Resolver quais namespaces da classe-alvo são class (não module) ──

  def resolve_namespace_classes
    parts = @target_class.split("::")
    parts.pop

    classes = Set.new
    parts.each_index do |i|
      full_name = parts[0..i].join("::")
      class_path = full_name.gsub("::", "/").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      source_file = @source_files.find { |f| f.end_with?("#{class_path}.rb") }

      next unless source_file && File.exist?(source_file)

      result = Prism.parse(File.read(source_file))
      visitor = ClassNameExtractor.new
      result.value.accept(visitor)
      classes.add(full_name) if visitor.class_name == full_name
    end

    classes
  end

  # ─── Inferir tipos de parâmetros de métodos via chamadas intra-classe ──

  def infer_method_param_types(attr_types)
    return {} unless @target_file && File.exist?(@target_file)

    source = File.read(@target_file)
    result = Prism.parse(source)

    visitor = IntraClassCallAnalyzer.new(attr_types: attr_types, method_type_resolver: method_type_resolver)
    result.value.accept(visitor)

    visitor.inferred_param_types
  end
end

require_relative "rbs_usage_analyzer/optional_param_extractor"
require_relative "rbs_usage_analyzer/class_name_extractor"
require_relative "rbs_usage_analyzer/class_body_attr_analyzer"
require_relative "rbs_usage_analyzer/intra_class_call_analyzer"
require_relative "rbs_usage_analyzer/initialize_body_analyzer"
require_relative "rbs_usage_analyzer/class_member_collector"
require_relative "rbs_usage_analyzer/def_collector"
require_relative "rbs_usage_analyzer/new_call_collector"
require_relative "rbs_usage_analyzer/method_type_resolver"
require_relative "rbs_usage_analyzer/caller_file_analyzer"
require_relative "rbs_usage_analyzer/rbs_builder"
require_relative "rbs_usage_analyzer/type_merger"
