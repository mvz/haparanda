# frozen_string_literal: true

require "sexp_processor"

module Haparanda
  # Process the handlebars AST just to do the whitespace stripping.
  class StandaloneWhitespaceHandler < SexpProcessor
    def initialize(prevent_indent: false)
      super()

      @prevent_indent = prevent_indent
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

      strip_whitespace_around_standalone_items(statements)

      s(:statements, *statements)
    end

    private

    # Strip whitespace around standalone items in a list of statements, while
    # recursing the general processing into each item at the right moment.
    #
    # The goal is to correctly remove whitespace for each item that is
    # 'standalone', i.e., appears on a line by itself with only whitespace
    # around.
    #
    # The tricky bit is that removing whitespace for one item may remove the
    # information needed for handling subsequent or nested items.
    #
    # To resolve this, this method splits the collection of what whitespace
    # changes to make from actually making them. In between these two parts, it
    # recurses into the nested items. This way, it ensures the nested process
    # has the original information available.
    def strip_whitespace_around_standalone_items(statements)
      before = nil

      [*statements, nil].each_cons(2).each do |item, after|
        before_space, inner_start_space, inner_end_space, after_space =
          collect_whitespace_information(before, item, after)

        process(item)

        apply_whitespace_clearing(before, item, after,
                                  before_space, inner_start_space,
                                  inner_end_space, after_space)

        before = item
      end
    end

    def collect_whitespace_information(before, item, after)
      before_space = preceding_whitespace? before
      after_space = following_whitespace? after

      if item.sexp_type == :block
        inner_start_space = following_whitespace? first_item(item)
        inner_end_space = preceding_whitespace? last_item(item)
      end
      return before_space, inner_start_space, inner_end_space, after_space
    end

    def apply_whitespace_clearing(before, item, after,
                                  before_space, inner_start_space,
                                  inner_end_space, after_space)
      case item.sexp_type
      when :block
        if before_space && inner_start_space
          clear_preceding_whitespace(before)
          clear_following_whitespace(first_item(item))
        end

        if inner_end_space && after_space
          clear_preceding_whitespace(last_item(item))
          clear_following_whitespace(after)
        end
      when :partial
        if !@prevent_indent && before_space && after_space
          indent = clear_preceding_whitespace(before)
          set_indent(item, indent)
        end
        clear_following_whitespace(after) if before_space && after
      when :comment
        if before_space && after_space
          clear_preceding_whitespace(before)
          clear_following_whitespace(after)
        end
      end
    end

    def first_item(container)
      return if container.nil?

      case container.sexp_type
      when :statements
        container.sexp_body.first
      when :block
        first_item(container[4] || container[5])
      when :inverse, :program
        first_item container[2]
      when :content
        container
      else
        raise NotImplementedError
      end
    end

    def last_item(container)
      return if container.nil?

      case container.sexp_type
      when :statements
        container.sexp_body.last
      when :block
        last_item(container[5] || container[4])
      when :inverse, :program
        last_item container[2]
      when :content
        container
      else
        raise NotImplementedError
      end
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

    # Strip trailing whitespace before but leave the \n. Return the stripped space.
    def clear_preceding_whitespace(before)
      if (match = before[1].match(/(.*\n)([ \t]+)$/))
        before[1] = match[1]
        match[2]
      end
    end

    # Strip leading whitespace after, including the \n if present
    def clear_following_whitespace(after)
      after[1] = after[1].sub(/^[ \t]*(\n|\r\n)?/, "")
    end

    def set_indent(item, indent)
      item << s(:indent, indent)
    end
  end
end
