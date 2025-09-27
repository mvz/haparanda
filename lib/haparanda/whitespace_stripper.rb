# frozen_string_literal: true

require "sexp_processor"

module Haparanda
  # Process the handlebars AST just to do the whitespace stripping.
  class WhitespaceStripper < SexpProcessor
    def initialize
      super

      self.require_empty = false
    end

    def process(expr)
      line = expr&.line
      super.tap { _1.line(line) if line }
    end

    def process_root(expr)
      _, statements = expr

      statements = process(statements)
      s(:root, statements)
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

      statements = program&.at(2)&.sexp_body
      if statements
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
        items = statements.sexp_body
        strip_initial_whitespace(items.first, open_strip)
        strip_final_whitespace(items.last, close_strip)
      end
      # TODO: Handle :block sexp_type

      s(:inverse, block_params, statements, open_strip, close_strip)
    end

    def process_statements(expr)
      statements = expr.sexp_body

      strip_pairwise_sibling_whitespace(statements)

      statements = statements.map { process(_1) }

      s(:statements, *statements)
    end

    private

    def strip_pairwise_sibling_whitespace(statements)
      statements.each_cons(2) do |prev, item|
        strip_final_whitespace(prev, open_strip_for(item)) if item.sexp_type != :content
        strip_initial_whitespace(item, close_strip_for(prev)) if prev.sexp_type != :content
      end
    end

    def strip_initial_whitespace(item, strip)
      item[1] = item[1].sub(/^\s*/, "") if item.sexp_type == :content && strip[2]
    end

    def strip_final_whitespace(item, strip)
      item[1] = item[1].sub(/\s*$/, "") if item.sexp_type == :content && strip&.at(1)
    end

    def open_strip_for(item)
      case item.sexp_type
      when :block
        item.at(-2)
      else
        item.last
      end
    end

    def close_strip_for(item)
      item.last
    end
  end
end
