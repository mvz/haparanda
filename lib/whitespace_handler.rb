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

    if program && (statements = program[2]&.sexp_body)
      strip_initial_whitespace(statements.first, open_strip)
      strip_final_whitespace(statements.last, close_strip)
    end

    program = process(program)
    inverse_chain = process(inverse_chain)

    s(:block, name, params, hash, program, inverse_chain, open_strip, close_strip)
  end

  def process_statements(expr)
    statements = expr.sexp_body

    statements.each_cons(2) do |prev, item|
      strip_final_whitespace(prev, item.last) if item.sexp_type != :content
      strip_initial_whitespace(item, prev.last) if prev.sexp_type != :content
    end
    results = statements.map { process(_1) }
    s(:statements, *results)
  end

  def strip_initial_whitespace(item, strip)
    item[1] = item[1].sub(/^\s*/, "") if item.sexp_type == :content && strip[2]
  end

  def strip_final_whitespace(item, strip)
    item[1] = item[1].sub(/\s*$/, "") if item.sexp_type == :content && strip&.at(1)
  end
end
