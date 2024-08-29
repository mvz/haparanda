# frozen_string_literal: true

require "sexp_processor"

# Process the handlebars AST just to do the whitespace stripping.
class WhitespaceHandler < SexpProcessor
  def initialize
    super

    self.require_empty = false
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
    results = statements.map { process(_1) }
    s(:statements, *results)
  end
end
