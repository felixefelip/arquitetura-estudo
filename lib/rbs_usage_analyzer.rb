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

    # Identificar parâmetros opcionais do initialize
    optional_params = extract_optional_init_params

    build_full_rbs(target_members, init_arg_types, attr_types, optional_params)
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

  class OptionalParamExtractor < Prism::Visitor
    attr_reader :optional_params

    def initialize
      @optional_params = Set.new
    end

    def visit_def_node(node)
      return super unless node.name == :initialize
      params = node.parameters
      return unless params&.respond_to?(:keywords)

      params.keywords.each do |kw|
        if kw.is_a?(Prism::OptionalKeywordParameterNode)
          @optional_params.add(kw.name.to_s)
        end
      end

      params.optionals.each do |p|
        @optional_params.add(p.name.to_s) if p.respond_to?(:name)
      end if params.respond_to?(:optionals)
    end
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

  class ClassNameExtractor < Prism::Visitor
    attr_reader :class_name

    def initialize
      @namespace = []
      @class_name = nil
    end

    def visit_module_node(node)
      @namespace.push(extract_const_name(node.constant_path))
      super
      @namespace.pop
    end

    def visit_class_node(node)
      name = extract_const_name(node.constant_path)
      @class_name = (@namespace + [name]).join("::")
      super
    end

    private

    def extract_const_name(node)
      RbsUsageAnalyzer.extract_constant_path(node) || node.to_s
    end
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

  class ClassBodyAttrAnalyzer < Prism::Visitor
    attr_reader :attr_types

    def initialize(attr_names:)
      @attr_names = attr_names
      @attr_types = {}
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

  # Estrutura que representa um membro da classe
  Member = Struct.new(:kind, :name, :signature, :visibility, keyword_init: true)

  class ClassMemberCollector < Prism::Visitor
    attr_reader :members, :superclass_name

    CONTROLLER_BASES = %w[ApplicationController ActionController::Base ActionController::API].freeze

    def initialize(comments:, lines:)
      @comments = comments
      @lines = lines
      @members = []
      @current_visibility = :public
      @is_controller = false
      @superclass_name = nil
    end

    def visit_class_node(node)
      if node.superclass
        @superclass_name = RbsUsageAnalyzer.extract_constant_path(node.superclass)
        @is_controller = CONTROLLER_BASES.include?(@superclass_name)
      end
      super
    end

    def visit_def_node(node)
      name = node.name.to_s
      sig = find_rbs_signature(@comments, @lines, node.location.start_line)

      # Extrair parâmetros do def para gerar assinatura básica se não tiver anotação
      params_sig = extract_params_signature(node)

      signature = if sig
                    "#{name}: #{sig}"
                  else
                    return_type = if @is_controller && @current_visibility == :public
                                   "void"
                                 else
                                   infer_return_type(node) || "untyped"
                                 end
                    "#{name}: #{params_sig} -> #{return_type}"
                  end

      @members << Member.new(
        kind: :method,
        name: name,
        signature: signature,
        visibility: @current_visibility
      )

      super
    end

    def visit_call_node(node)
      case node.name
      when :private
        if node.arguments.nil?
          # `private` sem args muda visibilidade padrão
          @current_visibility = :private
        end
      when :protected
        if node.arguments.nil?
          @current_visibility = :protected
        end
      when :public
        if node.arguments.nil?
          @current_visibility = :public
        end
      when :attr_accessor, :attr_reader, :attr_writer
        extract_attrs(node)
      end

      super
    end

    private

    def extract_attrs(node)
      return unless node.arguments

      # Buscar anotação inline na mesma linha: attr_accessor :foo #: Type
      attr_line = node.location.start_line
      inline_type = find_inline_type_same_line(@comments, attr_line)

      node.arguments.arguments.each do |arg|
        next unless arg.is_a?(Prism::SymbolNode)
        attr_name = arg.unescaped
        type = inline_type || "untyped"

        @members << Member.new(
          kind: node.name,
          name: attr_name,
          signature: "#{attr_name}: #{type}",
          visibility: @current_visibility
        )
      end
    end

    def find_inline_type_same_line(comments, line)
      comments.each do |comment|
        next unless comment.location.start_line == line
        text = comment.location.slice
        if text =~ /#:\s*(.+)/
          return $1.strip
        end
      end
      nil
    end

    def find_rbs_signature(comments, lines, def_line)
      # Buscar comentário rbs-inline acima do def (em sua própria linha dedicada)
      comments.each do |comment|
        comment_line = comment.location.start_line
        next unless comment_line.between?(def_line - 3, def_line - 1)
        next unless lines_between_are_blank_or_comments(lines, comment_line, def_line)

        # Ignorar comentários inline (na mesma linha de código, ex: attr_accessor :x #: Type)
        source_line = lines[comment_line - 1]
        if source_line
          code_before_comment = source_line[0...comment.location.start_column].strip
          next if !code_before_comment.empty?
        end

        text = comment.location.slice

        # #: (args) -> ReturnType  ou  #: -> ReturnType
        if text =~ /#:\s*(.+)/
          return $1.strip
        end

        # @rbs (args) -> ReturnType
        if text =~ /@rbs\s+(.+)/
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

    def extract_params_signature(node)
      params = node.parameters
      return "()" unless params

      parts = []

      # Parâmetros posicionais obrigatórios
      params.requireds.each do |p|
        parts << param_name(p)
      end if params.respond_to?(:requireds)

      # Parâmetros opcionais
      params.optionals.each do |p|
        parts << "?#{param_name(p)}"
      end if params.respond_to?(:optionals)

      # Rest param
      if params.respond_to?(:rest) && params.rest
        parts << "*untyped"
      end

      # Keywords obrigatórios
      params.keywords.each do |p|
        case p
        when Prism::RequiredKeywordParameterNode
          parts << "#{p.name}: untyped"
        when Prism::OptionalKeywordParameterNode
          parts << "?#{p.name}: untyped"
        end
      end if params.respond_to?(:keywords)

      # Keyword rest
      if params.respond_to?(:keyword_rest) && params.keyword_rest
        parts << "**untyped"
      end

      # Block
      if params.respond_to?(:block) && params.block
        parts << "?{ (untyped) -> untyped }"
      end

      "(#{parts.join(", ")})"
    end

    def param_name(param)
      case param
      when Prism::RequiredParameterNode
        "untyped #{param.name}"
      else
        "untyped"
      end
    end

    def infer_return_type(defn)
      body = defn.body
      return nil unless body

      last_stmt = case body
                  when Prism::StatementsNode then body.body.last
                  else body
                  end

      return nil unless last_stmt

      infer_type_from_node(last_stmt)
    end

    def infer_type_from_node(node)
      case node
      when Prism::CallNode
        if node.name == :new && node.receiver
          RbsUsageAnalyzer.extract_constant_path(node.receiver)
        end
      when Prism::StringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::FloatNode then "Float"
      when Prism::SymbolNode then "Symbol"
      when Prism::TrueNode then "bool"
      when Prism::FalseNode then "bool"
      when Prism::NilNode then "nil"
      when Prism::ArrayNode then "Array[untyped]"
      when Prism::HashNode then "Hash[untyped, untyped]"
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        RbsUsageAnalyzer.extract_constant_path(node)
      end
    end
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
      method_type_resolver: method_type_resolver
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

  # ─── Visitors auxiliares ───────────────────────────────────────────

  class DefCollector < Prism::Visitor
    attr_reader :defs

    def initialize
      @defs = []
    end

    def visit_def_node(node)
      @defs << node
      super
    end
  end

  class NewCallCollector < Prism::Visitor
    attr_reader :usages

    AR_FINDER_METHODS = %i[find find_by find_by! first first! last last! take take! create create! find_or_create_by find_or_create_by! find_sole_by].freeze

    def initialize(target_class:, method_return_types:, local_var_types:, method_type_resolver: nil)
      @target_class = target_class
      @method_return_types = method_return_types
      @local_var_types = local_var_types
      @method_type_resolver = method_type_resolver
      @usages = []
    end

    def visit_def_node(node)
      old_vars = @local_var_types.dup
      collect_local_assignments(node)
      super
      @local_var_types = old_vars
    end

    def visit_call_node(node)
      if node.name == :new && node.receiver
        receiver_name = RbsUsageAnalyzer.extract_constant_path(node.receiver)
        if receiver_name && match_class?(receiver_name)
          args = extract_keyword_args(node)
          @usages << args unless args.empty?
        end
      end
      super
    end

    private

    def match_class?(name)
      normalized_target = @target_class.sub(/\A::/, "")
      normalized_name = name.sub(/\A::/, "")
      normalized_name == normalized_target
    end

    def collect_local_assignments(defn)
      body = defn.body
      return unless body

      stmts = case body
              when Prism::StatementsNode then body.body
              else [body]
              end

      stmts.each do |stmt|
        if stmt.is_a?(Prism::LocalVariableWriteNode)
          var_name = stmt.name.to_s
          if stmt.value.is_a?(Prism::CallNode)
            if stmt.value.receiver.nil?
              # aluno_dto = build_dto
              method_name = stmt.value.name.to_s
              if @method_return_types[method_name]
                @local_var_types[var_name] = @method_return_types[method_name]
              end
            elsif stmt.value.name == :new && stmt.value.receiver
              # aluno_dto = Academico::Aluno::Matricular::Dto.new(...)
              class_name = RbsUsageAnalyzer.extract_constant_path(stmt.value.receiver)
              @local_var_types[var_name] = class_name if class_name
            elsif AR_FINDER_METHODS.include?(stmt.value.name) && stmt.value.receiver
              # record = Record.find_by!(...) → type Record
              class_name = RbsUsageAnalyzer.extract_constant_path(stmt.value.receiver)
              @local_var_types[var_name] = class_name if class_name
            end
          end
        end
      end
    end

    def extract_keyword_args(call_node)
      args = {}
      return args unless call_node.arguments

      call_node.arguments.arguments.each do |arg|
        next unless arg.is_a?(Prism::KeywordHashNode)

        arg.elements.each do |elem|
          next unless elem.is_a?(Prism::AssocNode)

          key = extract_symbol_key(elem.key)
          next unless key

          value_type = resolve_value_type(elem.value)
          args[key] = value_type
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
      when Prism::CallNode
        if node.receiver.nil?
          @method_return_types[node.name.to_s] || "untyped"
        elsif node.name == :new && node.receiver
          RbsUsageAnalyzer.extract_constant_path(node.receiver) || "untyped"
        else
          resolve_method_chain(node) || "untyped"
        end
      when Prism::StringNode then "String"
      when Prism::IntegerNode then "Integer"
      when Prism::FloatNode then "Float"
      when Prism::SymbolNode then "Symbol"
      when Prism::TrueNode, Prism::FalseNode then "bool"
      when Prism::NilNode then "nil"
      when Prism::ArrayNode then "Array[untyped]"
      when Prism::HashNode then "Hash[untyped, untyped]"
      when Prism::ConstantReadNode, Prism::ConstantPathNode
        RbsUsageAnalyzer.extract_constant_path(node) || "untyped"
      when Prism::ImplicitNode
        resolve_value_type(node.value)
      else
        "untyped"
      end
    end

    # Resolver receiver.method() → tipo do retorno do method no receiver
    def resolve_method_chain(node)
      return nil unless @method_type_resolver

      receiver_type = resolve_receiver_type(node.receiver)
      return nil unless receiver_type && receiver_type != "untyped"

      @method_type_resolver.resolve(receiver_type, node.name.to_s)
    end

    # Resolver o tipo do receiver de um method call
    def resolve_receiver_type(node)
      case node
      when Prism::LocalVariableReadNode
        @local_var_types[node.name.to_s]
      when Prism::CallNode
        if node.receiver.nil?
          # Implicit method call (ex: attr_reader como aluno_dto)
          @method_return_types[node.name.to_s]
        elsif node.name == :new && node.receiver
          RbsUsageAnalyzer.extract_constant_path(node.receiver)
        end
      when Prism::SelfNode
        nil # self → seria a própria classe, não resolvemos por enquanto
      end
    end
  end

  # ─── Resolvedor de tipos inter-procedural ──────────────────────────
  # Dado um class_name e method_name, encontra o arquivo fonte da classe,
  # parseia e retorna o tipo de retorno do método.
  # Também infere tipos de attrs via keyword defaults e call-sites.

  class MethodTypeResolver
    def initialize(source_files)
      @source_files = source_files
      @cache = {}
      @building = Set.new # guard contra recursão infinita
    end

    def resolve(class_name, method_name)
      return nil unless class_name && class_name != "untyped"

      class_types = resolve_all(class_name)
      class_types[method_name] || class_types[method_name.chomp("!").chomp("?")]
    end

    def resolve_all(class_name)
      return {} unless class_name && class_name != "untyped"
      @cache[class_name] ||= build_class_types(class_name)
    end

    private

    def build_class_types(class_name)
      return {} if @building.include?(class_name)
      @building.add(class_name)

      types = {}
      file = find_class_file(class_name)

      if file && File.exist?(file)
        source = File.read(file)
        result = Prism.parse(source)
        comments = result.comments
        lines = source.lines

        # 1. Tipos anotados via ClassMemberCollector
        collector = RbsUsageAnalyzer::ClassMemberCollector.new(comments: comments, lines: lines)
        result.value.accept(collector)

        attr_names = Set.new
        collector.members.each do |member|
          case member.kind
          when :method
            if member.signature =~ /->\s*(.+)$/
              types[member.name] = $1.strip
            end
          when :attr_accessor, :attr_reader
            attr_names.add(member.name)
            if member.signature =~ /\w+:\s*(.+)/
              type = $1.strip
              types[member.name] = type unless type == "untyped"
            end
          end
        end

        # 2. Tipos inferidos via keyword defaults do initialize
        init_visitor = RbsUsageAnalyzer::InitializeBodyAnalyzer.new
        result.value.accept(init_visitor)

        init_visitor.keyword_defaults.each do |param_name, default_type|
          init_visitor.self_assignments.each do |attr_name, info|
            if info[:kind] == :param && info[:name] == param_name && !types[attr_name]
              types[attr_name] = default_type
            end
          end
        end

        # 3. Inferir attrs restantes via call-sites de ClassName.new(...)
        untyped_attr_params = {}
        init_visitor.self_assignments.each do |attr_name, info|
          if info[:kind] == :param && attr_names.include?(attr_name) && !types[attr_name]
            untyped_attr_params[info[:name]] = attr_name
          end
        end

        if untyped_attr_params.any?
          infer_attrs_from_call_sites(class_name, types, untyped_attr_params)
        end
      end

      # 4. Fallback: buscar em arquivos RBS (ex: rbs_rails para AR models)
      rbs_types = lookup_rbs_types(class_name)
      rbs_types.each { |name, type| types[name] ||= type }

      @building.delete(class_name)
      types
    end

    # Escaneia source files para encontrar ClassName.new(key: val)
    # e inferir os tipos dos kwargs → attrs
    def infer_attrs_from_call_sites(class_name, types, param_to_attr)
      short_name = class_name.split("::").last

      @source_files.each do |file|
        source = File.read(file) rescue next
        next unless source.include?(short_name)

        result = Prism.parse(source)

        local_var_types = {}
        visitor = RbsUsageAnalyzer::NewCallCollector.new(
          target_class: class_name,
          method_return_types: {},
          local_var_types: local_var_types,
          method_type_resolver: nil
        )
        result.value.accept(visitor)

        visitor.usages.each do |usage|
          usage.each do |param_name, type|
            if param_to_attr.key?(param_name) && type != "untyped"
              attr_name = param_to_attr[param_name]
              types[attr_name] ||= type
            end
          end
        end
      end
    end

    # Busca tipos em arquivos .rbs gerados (ex: rbs_rails para AR models)
    def lookup_rbs_types(class_name)
      types = {}
      class_path = class_name.sub(/\A::/, "").gsub("::", "/").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      Dir["sig/rbs_rails/**/*.rbs"].each do |rbs_file|
        next unless rbs_file.end_with?("#{class_path}.rbs")
        content = File.read(rbs_file)
        content.scan(/^\s*def (\w+): \(\) -> (.+)$/) do
          name, type = $1, $2
          types[name] ||= type.strip
        end
      end
      types
    end

    def find_class_file(class_name)
      class_path = class_name.sub(/\A::/, "").gsub("::", "/").gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      @source_files.find { |f| f.end_with?("#{class_path}.rb") }
    end
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
