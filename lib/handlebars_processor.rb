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
      @stack.push value
      result = block.call
      @stack.pop
      result
    end

    def to_s
      @stack.last.to_s
    end
  end

  def initialize(input)
    super()

    self.require_empty = false

    @input = Input.new(input)
    @helpers = {
      if: ->(value, block, _else_block) { block.call if value },
      unless: ->(value, block, _else_block) { block.call unless value },
      with: lambda do |value, block, else_block|
        if value
          @input.with_new_context(value, &block)
        else
          @input.with_new_context(value, &else_block)
        end
      end,
      each: lambda do |value, block, _else_block|
        break unless value

        value = value.values if value.is_a? Hash
        @input.with_new_data do
          value.each_with_index.map do |item, index|
            @input.set_data(:index, index)
            @input.with_new_context(item, &block)
          end.join
        end
      end
    }
  end

  def apply(expr)
    result = process(expr)
    result[1]
  end

  def process_mustache(expr)
    _, path, _params, _hash, escaped, _strip = expr
    value = evaluate_path(path)
    value = if escaped
              escape(value.to_s)
            else
              value.to_s
            end
    s(:result, value)
  end

  def process_block(expr)
    _, name, params, _hash, program, inverse_chain, = expr
    else_program = inverse_chain.sexp_body[1] if inverse_chain
    if params.sexp_body.any?
      values = params.sexp_body.map { evaluate_path _1 }
      helper_name = name[2][1].to_sym
      value = @helpers.fetch(helper_name).call(*values,
                                               -> { apply(program) },
                                               -> { apply(else_program) })
      s(:result, value.to_s)
    else
      value = evaluate_path(name)
      evaluate_program_with_value(program, value)
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

  private

  def evaluate_program_with_value(program, value)
    return s(:result, "") unless value

    case value
    when Array
      parts = value.each_with_index.map do |elem, index|
        @input.set_data(:index, index)
        @input.with_new_context(elem) do
          apply(program)
        end
      end
      s(:result, parts.join)
    else
      @input.with_new_context(value) do
        process(program)
      end
    end
  end

  def evaluate_path(path)
    path = process(path)
    case path.sexp_type
    when :segments
      data, elements = path.sexp_body
    else
      elements = path[1]
    end
    if data
      @input.data(*elements)
    else
      @input.dig(*elements)
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
