# frozen_string_literal: true

require "sexp_processor"

module Haparanda
  # Process the handlebars AST just to do the whitespace stripping.
  class WhitespaceHandler < SexpProcessor # rubocop:disable Metrics/ClassLength
    def initialize(ignore_standalone: false)
      super()

      @ignore_standalone = ignore_standalone

      self.require_empty = false
    end

    def process_root(expr)
      _, statements = expr

      statements = process(statements)
      item = statements.sexp_body[0]
      if item.sexp_type == :block
        content = item.dig(4, 2, 1)
        clear_following_whitespace(content) if following_whitespace?(content)
      end
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

      if statements && inverse_chain
        strip_standalone_whitespace(statements.last, first_item(inverse_chain))
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

      statements.each_cons(2) do |prev, item|
        strip_final_whitespace(prev, open_strip_for(item)) if item.sexp_type != :content
        strip_initial_whitespace(item, close_strip_for(prev)) if prev.sexp_type != :content

        strip_standalone_whitespace(prev, item.dig(4, 2, 1)) if item.sexp_type == :block
        strip_standalone_whitespace(last_item(prev), item) if prev.sexp_type == :block
      end
      statements = statements.map { process(_1) }

      s(:statements, *statements)
    end

    private

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

    def strip_initial_whitespace(item, strip)
      item[1] = item[1].sub(/^\s*/, "") if item.sexp_type == :content && strip[2]
    end

    def strip_final_whitespace(item, strip)
      item[1] = item[1].sub(/\s*$/, "") if item.sexp_type == :content && strip&.at(1)
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
      return if @ignore_standalone

      before[1] = before[1].sub(/\n[ \t]+$/, "\n")
    end

    # Strip leading whitespace after including the \n
    def clear_following_whitespace(after)
      return if @ignore_standalone

      after[1] = after[1].sub(/^[ \t]*\n/, "")
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
