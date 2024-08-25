# frozen_string_literal: true

require "sexp_processor"

class HandlebarsProcessor < SexpProcessor # rubocop:disable Metrics/ClassLength
  class SafeString < String
    def to_s
      self
    end
  end

  class Input
    def initialize(value)
      @stack = [value]
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

  class Data
    def initialize(data = {})
      @data = data
    end

    def data(*keys)
      @data.dig(*keys)
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

    def respond_to_missing?(method_name)
      @data.key? method_name
    end

    def method_missing(method_name, *_args)
      @data[method_name] if @data.key? method_name
    end
  end

  class NoData
    def set_data(key, value); end

    def with_new_data(&block)
      block.call
    end
  end

  class Options
    def initialize(fn:, inverse:, hash:, data:)
      @fn = fn
      @inverse = inverse
      @hash = hash
      @data = data
    end

    attr_reader :hash, :data

    def fn(arg = nil)
      @fn&.call(arg)
    end

    def inverse(arg = nil)
      @inverse&.call(arg)
    end
  end

  def initialize(input, custom_helpers = nil, data: {})
    super()

    self.require_empty = false

    @input = Input.new(input)
    @data = data ? Data.new(data) : NoData.new

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
    _, path, params, hash, escaped, _strip = expr
    params = process(params)[1]
    hash = process(hash)[1] if hash
    data, elements = path_segments process(path)
    value = lookup_path(data, elements)
    value = execute_in_context(value, params, hash: hash) if value.respond_to? :call
    value = value.to_s
    value = escape(value) if escaped
    s(:result, value)
  end

  def process_block(expr)
    _, name, params, hash, program, inverse_chain, = expr
    hash = process(hash)[1] if hash
    else_program = inverse_chain.sexp_body[1] if inverse_chain
    arguments = process(params)[1]

    path = process(name)
    data, elements = path_segments(path)
    value = lookup_path(data, elements)

    evaluate_program_with_value(value, arguments, program, else_program, hash)
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

  def process_hash(expr)
    _, *entries = expr
    hash = entries.to_h do |_, key, value|
      value = evaluate_expr(value)
      [key.to_sym, value]
    end
    s(:hash, hash)
  end

  private

  def evaluate_program_with_value(value, arguments, program, else_program, hash)
    fn = make_contextual_lambda(program)
    inverse = make_contextual_lambda(else_program)

    if value.respond_to? :call
      value = execute_in_context(value, arguments, fn: fn, inverse: inverse, hash: hash)
      return s(:result, value.to_s)
    end

    case value
    when Array
      return s(:result, inverse.call(@input)) if value.empty?

      parts = value.each_with_index.map do |elem, index|
        @data.set_data(:index, index)
        fn.call(elem)
      end
      s(:result, parts.join)
    else
      result = value ? fn.call(value) : inverse.call(@input)
      s(:result, result)
    end
  end

  def make_contextual_lambda(program)
    if program
      ->(item) { @input.with_new_context(item) { apply(program) } }
    else
      ->(_item) { "" }
    end
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
      elements = [path.sexp_type]
    else
      elements = [path[1]]
    end
    return data, elements
  end

  def lookup_path(data, elements)
    if data
      @data.data(*elements)
    elsif elements.count == 1 && @helpers.key?(elements.first)
      @helpers[elements.first]
    else
      @input.dig(*elements)
    end
  end

  def execute_in_context(callable, params = [], fn: nil, inverse: nil, hash: nil)
    num_params = callable.arity
    raise NotImplementedError if num_params < 0

    args = [*params, Options.new(fn: fn, inverse: inverse, hash: hash, data: @data)]
    args = args.take(num_params)
    @input.instance_exec(*args, &callable)
  end

  def handle_if(value, options)
    if value
      options.fn(@input)
    else
      options.inverse(@input)
    end
  end

  def handle_unless(value, options)
    options.fn(@input) unless value
  end

  def handle_with(value, options)
    if value
      options.fn(value)
    else
      options.inverse(value)
    end
  end

  def handle_each(value, options)
    return unless value

    value = value.values if value.is_a? Hash
    @data.with_new_data do
      value.each_with_index.map do |item, index|
        @data.set_data(:index, index)
        options.fn(item)
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
    return str if str.is_a? SafeString

    str.gsub(/[&<>"'`=]/) do |chr|
      ESCAPE[chr]
    end
  end
end
