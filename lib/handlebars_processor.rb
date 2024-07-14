# frozen_string_literal: true

require "sexp_processor"

class HandlebarsProcessor < SexpProcessor # rubocop:disable Metrics/ClassLength
  class Input
    def initialize(data)
      @stack = [data]
    end

    def dig(*keys)
      data = @stack.last
      keys.each do |key|
        next if %i[.. . this].include? key

        data = case data
               when Hash
                 data[key]
               when nil
                 nil
               else
                 data.send key
               end
      end

      data
    end

    def push(data)
      @stack.push data
    end

    def pop(data)
      @stack.pop data
    end

    def with_new_context(data, &block)
      @stack.push data
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
        value.map { |item| @input.with_new_context(item, &block) }.join
      end
    }
  end

  def apply(expr)
    # FIXME: Using #deep_clone is not great for performance! Switch to
    # non-consuming processing.
    result = process(expr.deep_clone)
    result[1]
  end

  def process_mustache(expr)
    _, path, _params, _hash, escaped, _strip = expr.shift(6)
    value = evaluate_path(path)
    value = if escaped
              escape(value.to_s)
            else
              value.to_s
            end
    s(:result, value)
  end

  def process_block(expr)
    _, name, params, _hash, program, inverse_chain, = expr.shift(8)
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
    expr.shift
    statements = shift_all(expr)

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
    _, _params, statements, = expr.shift(3)
    statements = process(statements)[1] if statements
    s(:result, statements.to_s)
  end

  def process_comment(expr)
    _, _comment, = expr.shift(3)
    s(:result, "")
  end

  def process_path(expr)
    _, _data = expr.shift(2)
    segments = shift_all(expr)
    segments = segments.each_slice(2).map { |elem, _sep| elem[1].to_sym }
    s(:segments, segments)
  end

  def evaluate_program_with_value(program, value)
    return s(:result, "") unless value

    case value
    when Array
      parts = value.map do |elem|
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
    elements = process(path)
    @input.dig(*elements[1])
  end

  def shift_all(expr)
    result = []
    result << expr.shift while expr.any?
    result
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
