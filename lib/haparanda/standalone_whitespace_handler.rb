# frozen_string_literal: true

require "sexp_processor"

module Haparanda
  # Process the handlebars AST just to do the whitespace stripping.
  class StandaloneWhitespaceHandler < SexpProcessor
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
      item = statements.sexp_body[0] if statements
      if item&.sexp_type == :block
        content = item.dig(4, 2, 1)
        clear_following_whitespace(content) if following_whitespace?(content)
      end
      s(:root, statements)
    end

    def process_block(expr)
      _, name, params, hash, program, inverse_chain, open_strip, close_strip = expr

      program = process(program)
      inverse_chain = process(inverse_chain)

      statements = program&.at(2)&.sexp_body

      if statements && inverse_chain
        strip_standalone_whitespace(statements.last, first_item(inverse_chain))
      end

      s(:block, name, params, hash, program, inverse_chain, open_strip, close_strip)
    end

    def process_statements(expr)
      statements = expr.sexp_body

      strip_whitespace_after_standalone_partials(statements)
      strip_pairwise_sibling_whitespace(statements)

      statements = statements.map { process(_1) }

      s(:statements, *statements)
    end

    private

    def strip_whitespace_after_standalone_partials(statements)
      statements.each_cons(3) do |prev, partial, item|
        next if partial.sexp_type != :partial
        next unless preceding_whitespace? prev

        strip_initial_whitespace(item)
      end
    end

    def strip_pairwise_sibling_whitespace(statements)
      statements.each_cons(2) do |prev, item|
        strip_standalone_whitespace(prev, first_item(item)) if item.sexp_type == :block
        strip_standalone_whitespace(last_item(prev), item) if prev.sexp_type == :block
      end
    end

    def first_item(container)
      case container.sexp_type
      when :statements
        container.sexp_body.first
      when :block
        container.dig(4, 2, 1)
      when :inverse
        first_item container[2]
      else
        raise NotImplementedError
      end
    end

    def last_item(container)
      return if container.nil?

      case container.sexp_type
      when :block
        last_item(container[5] || container[4])
      when :statements
        container.sexp_body.last
      when :inverse, :program
        last_item container[2]
      when :content
        container
      else
        raise NotImplementedError
      end
    end

    def strip_initial_whitespace(item)
      item[1] = item[1].sub(/^\s*/, "") if item.sexp_type == :content
    end

    def strip_standalone_whitespace(before, after)
      return unless preceding_whitespace? before
      return unless following_whitespace? after

      clear_preceding_whitespace(before)
      clear_following_whitespace(after)
    end

    def preceding_whitespace?(before)
      before&.sexp_type == :content && before[1] =~ /\n\s*$/
    end

    def following_whitespace?(after)
      after&.sexp_type == :content && after[1] =~ /^\s*\n/
    end

    # Strip trailing whitespace before but leave the \n
    def clear_preceding_whitespace(before)
      before[1] = before[1].sub(/\n[ \t]+$/, "\n")
    end

    # Strip leading whitespace after including the \n
    def clear_following_whitespace(after)
      after[1] = after[1].sub(/^[ \t]*\n/, "")
    end
  end
end
