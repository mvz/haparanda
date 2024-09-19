# frozen_string_literal: true

require "sexp_processor"

# Process the handlebars AST just to do the whitespace stripping.
class WhitespaceHandler < SexpProcessor
  def initialize
    super

    self.require_empty = false
  end

  def process_block(expr)
    _, name, params, hash, program, inverse_chain, open_strip, close_strip = expr

    program = process(program)
    if inverse_chain && inverse_chain.last.nil?
      body = inverse_chain.sexp_body
      body[-1] = close_strip
      inverse_chain.sexp_body = body
    end
    inverse_chain = process(inverse_chain)

    if program && (statements = program[2]&.sexp_body)
      strip_initial_whitespace(statements.first, open_strip)
      strip_final_whitespace(statements.last, close_strip)
    end

    s(:block, name, params, hash, program, inverse_chain, open_strip, close_strip)
  end

  def process_inverse(expr)
    _, block_params, statements, open_strip, close_strip = expr

    block_params = process(block_params)
    statements = process(statements)

    case statements.sexp_type
    when :statements
      if (items = statements&.sexp_body)
        strip_initial_whitespace(items.first, open_strip)
        strip_final_whitespace(items.last, close_strip)
      end
    end
    # TODO: Handle :block sexp_type

    s(:inverse, block_params, statements, open_strip, close_strip)
  end

  def process_statements(expr)
    statements = expr.sexp_body

    statements = statements.map { process(_1) }
    statements = combine_contents(statements)

    statements.each_cons(2) do |prev, item|
      strip_final_whitespace(prev, item.last) if item.sexp_type != :content
      strip_initial_whitespace(item, prev.last) if prev.sexp_type != :content
    end
    s(:statements, *statements)
  end

  def strip_initial_whitespace(item, strip)
    item[1] = item[1].sub(/^\s*/, "") if item.sexp_type == :content && strip[2]
  end

  def strip_final_whitespace(item, strip)
    item[1] = item[1].sub(/\s*$/, "") if item.sexp_type == :content && strip&.at(1)
  end

  def combine_contents(statements)
    return statements if statements.length < 2

    prev = nil
    result = []

    statements.each do |item|
      if prev
        if item.sexp_type == :content
          prev[1] += item[1]
        else
          result << item
          prev = nil
        end
      else
        result << item
        prev = item if item.sexp_type == :content
      end
    end

    result
  end
end
