# frozen_string_literal: true

require "sexp_processor"

class HandlebarsProcessor < SexpProcessor # rubocop:disable Metrics/ClassLength
  class Input
    def initialize(value)
      @stack = [value]
      @data = {}
    end

    def dig(*keys)
      index = -1
      value = @stack[index]
      keys.each do |key|
        if key == :".."
          index -= 1
          value = @stack[index]
        end
        next if %i[.. . this].include? key

        value = case value
                when Hash
                  value[key]
                when nil
                  nil
                else
                  value.send key
                end
      end

      value
    end

    def data(key)
      @data[key]
    end

    def set_data(key, value)
      @data[key] = value
    end

    def with_new_data(&block)
      data = @data.clone
      result = block.call
      @data = data
      result
    end

    def with_new_context(value, &block)
      # TODO: This prevents a SystemStackError. Make this unnecessary, for
      # example by moving the stacking behavior out of the Input class.
      if self == value
        block.call
      else
        @stack.push value
        result = block.call
        @stack.pop
        result
      end
    end

    def to_s
      @stack.last.to_s
    end

    def this
      self
    end

    def respond_to_missing?(_method_name)
      true
    end

    def method_missing(method_name, *_args)
      dig(method_name)
    end
  end

  class Options
    def initialize(fn: nil) # rubocop:disable Naming/MethodParameterName
      @fn = fn
    end

    def fn(arg = nil)
      @fn&.call(arg)
    end
  end

  def initialize(input, custom_helpers = nil)
    super()

    self.require_empty = false

    @input = Input.new(input)

    custom_helpers ||= {}
    @helpers = {
      if: method(:handle_if),
      unless: method(:handle_unless),
      with: method(:handle_with),
      each: method(:handle_each)
    }.merge(custom_helpers)
  end

  def apply(expr)
    result = process(expr)
    result[1]
  end

  def process_mustache(expr)
    _, path, params, _hash, escaped, _strip = expr
    params = process(params)[1]
    if params.empty?
      value = evaluate_path(path)
      value = if escaped
                escape(value.to_s)
              else
                value.to_s
              end
    else
      helper_path = process(path)[2]
      helper = @helpers.fetch(helper_path[0]) { @input.dig(*helper_path) }
      value = execute_in_context(helper, params)
    end
    s(:result, value)
  end

  def process_block(expr)
    _, name, params, _hash, program, inverse_chain, = expr
    else_program = inverse_chain.sexp_body[1] if inverse_chain
    arguments = process(params)[1]
    if arguments.empty?
      path = process(name)
      data, elements = path_segments(path)
      value = lookup_path(data, elements)
      evaluate_program_with_value(value, program, else_program)
    else
      helper_name = name[2][1].to_sym
      value = @helpers.fetch(helper_name).call(*arguments,
                                               -> { apply(program) },
                                               -> { apply(else_program) })
      s(:result, value.to_s)
    end
  end

  def process_statements(expr)
    statements = expr.sexp_body

    statements.each_cons(2) do |prev, item|
      if prev.sexp_type == :content && item.sexp_type != :content
        strip = item.last
        prev[1] = prev[1].sub(/\s*$/, "") if strip[1]
      end
      if prev.sexp_type != :content && item.sexp_type == :content
        strip = prev.last
        item[1] = item[1].sub(/^\s*/, "") if strip[2]
      end
    end

    results = statements.map { process(_1)[1] }
    s(:result, results.join)
  end

  def process_program(expr)
    _, _params, statements, = expr
    statements = process(statements)[1] if statements
    s(:result, statements.to_s)
  end

  def process_comment(expr)
    _, _comment, = expr
    s(:result, "")
  end

  def process_path(expr)
    _, data, *segments = expr
    segments = segments.each_slice(2).map { |elem, _sep| elem[1].to_sym }
    s(:segments, data, segments)
  end

  def process_exprs(expr)
    _, *paths = expr
    values = paths.map { evaluate_expr(_1) }
    s(:values, values)
  end

  private

  def evaluate_program_with_value(value, program, _else_program)
    return s(:result, "") unless value

    fn = lambda { |item|
      @input.with_new_context(item) do
        apply(program)
      end
    }

    if value.respond_to? :call
      value = execute_in_context(value, [], program: fn)
      return s(:result, value.to_s)
    end

    case value
    when Array
      parts = value.each_with_index.map do |elem, index|
        @input.set_data(:index, index)
        fn.call(elem)
      end
      s(:result, parts.join)
    else
      result = fn.call(value)
      s(:result, result)
    end
  end

  def evaluate_path(expr)
    path = process(expr)
    data, elements = path_segments(path)
    value = lookup_path(data, elements)
    value = execute_in_context(value) if value.respond_to? :call
    value
  end

  def evaluate_expr(expr)
    path = process(expr)
    case path.sexp_type
    when :segments
      data, elements = path.sexp_body
      value = lookup_path(data, elements)
      value = execute_in_context(value) if value.respond_to? :call
      value
    when :undefined, :null
      nil
    else
      path[1]
    end
  end

  def path_segments(path)
    case path.sexp_type
    when :segments
      data, elements = path.sexp_body
    when :undefined, :null
      raise NotImplementedError
    else
      elements = [path[1]]
    end
    return data, elements
  end

  def lookup_path(data, elements)
    if data
      @input.data(*elements)
    elsif elements.count == 1 && @helpers.key?(elements.first)
      @helpers[elements.first]
    else
      @input.dig(*elements)
    end
  end

  def execute_in_context(callable, params = [], program: nil)
    num_params = callable.arity
    raise NotImplementedError if num_params < 0

    args = [*params, Options.new(fn: program)]
    args = args.take(num_params)
    @input.instance_exec(*args, &callable)
  end

  def handle_if(value, block, _else_block)
    block.call if value
  end

  def handle_unless(value, block, _else_block)
    block.call unless value
  end

  def handle_with(value, block, else_block)
    if value
      @input.with_new_context(value, &block)
    else
      @input.with_new_context(value, &else_block)
    end
  end

  def handle_each(value, block, _else_block)
    return unless value

    value = value.values if value.is_a? Hash
    @input.with_new_data do
      value.each_with_index.map do |item, index|
        @input.set_data(:index, index)
        @input.with_new_context(item, &block)
      end.join
    end
  end

  ESCAPE = {
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    '"' => "&quot;",
    "'" => "&#x27;",
    "`" => "&#x60;",
    "=" => "&#x3D;"
  }.freeze

  def escape(str)
    str.gsub(/[&<>"'`=]/) do |chr|
      ESCAPE[chr]
    end
  end
end
