# frozen_string_literal: true

require "sexp_processor"

module Haparanda
  # Process the handlebars AST just to combine subsequent :content items
  class ContentCombiner < SexpProcessor
    def initialize
      super

      self.require_empty = false
    end

    def process_statements(expr)
      statements = expr.sexp_body

      statements = combine_contents(statements)
      statements = statements.map { process(_1) }

      s(:statements, *statements)
    end

    def process(expr)
      line = expr.line
      super.tap { _1.line(line) if line }
    end

    private

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
end
