# frozen_string_literal: true

require_relative "content_combiner"
require_relative "standalone_whitespace_handler"
require_relative "whitespace_stripper"

module Haparanda
  # Parse a handlebars string to an AST in the form needed to apply input to it:
  # - parse the string into the raw AST
  # - combine subsequent :content items
  # - strip whitespace according to Handlebars' rules
  class Parser
    def initialize(ignore_standalone: false, prevent_indent: false, **)
      @ignore_standalone = ignore_standalone
      @prevent_indent = prevent_indent
    end

    def parse(text)
      expr = HandlebarsParser.new.parse(text)
      expr = ContentCombiner.new.process(expr)
      unless @ignore_standalone
        expr = StandaloneWhitespaceHandler.new(prevent_indent: @prevent_indent)
                                          .process(expr)
      end
      WhitespaceStripper.new.process(expr)
    end
  end
end
