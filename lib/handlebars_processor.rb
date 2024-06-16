# frozen_string_literal: true

require "sexp_processor"

class HandlebarsProcessor < SexpProcessor
  class Input
    def initialize(data)
      @data = data
    end

    def dig(*keys)
      data = @data
      keys.each do |key|
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

    def to_s
      @data.to_s
    end
  end

  def initialize(input)
    super()
    @input = Input.new(input)
  end

  def apply(expr)
    result = process(expr)
    result[1]
  end

  def process_mustache(expr)
    _, path, _params, _hash, = expr.shift(5)
    value = evaluate_path(path)
    s(:result, value.to_s)
  end

  def process_block(expr)
    _, name, params, hash, program, inverse_chain, = expr.shift(8)
    if params.sexp_body.any?
      values = params.sexp_body.map { evaluate_path _1 }
      helper_name = name[2][1].to_sym
      case helper_name
      when :unless
        if values[0]
          s(:result, "")
        else
          process(program)
        end
      else
        raise NotImplementedError
      end
    else
      value = evaluate_path(name)
      if value
        process(program)
      else
        s(:result, "")
      end
    end
  end

  def process_statements(expr)
    expr.shift
    statements = shift_all(expr)

    statements.each_cons(2) do |prev, item|
      if prev.sexp_type == :content && item.sexp_type != :content
        strip = item.last
        if strip[1]
          prev[1] = prev[1].sub(/\s*$/, "")
        end
      end
      if prev.sexp_type != :content && item.sexp_type == :content
        strip = prev.last
        if strip[2]
          item[1] = item[1].sub(/^\s*/, "")
        end
      end
    end

    results = statements.map { process(_1)[1] }
    s(:result, "#{results.join}")
  end

  def process_program(expr)
    _, params, statements, = expr.shift(3)
    statements = process(statements)[1] if statements
    s(:result, "#{statements}")
  end

  def process_comment(expr)
    _, _comment, = expr.shift(3)
    s(:result, "")
  end

  def process_path(expr)
    _, data = expr.shift(2)
    segments = shift_all(expr)
    segments = segments.each_slice(2).map { |elem, sep| elem[1].to_sym }
    s(:segments, segments)
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
end
