# frozen_string_literal: true

require_relative "content_combiner"
require_relative "whitespace_handler"

module Haparanda
  # Parse a handlebars string to an AST in the form needed to apply input to it:
  # - parse the string into the raw AST
  # - combine subsequent :content items
  # - strip whitespace according to Handlebars' rules
  class Parser
    def initialize(ignore_standalone: false, **)
      @ignore_standalone = ignore_standalone
    end

    def parse(text)
      expr = HandlebarsParser.new.parse(text)
      expr = ContentCombiner.new.process(expr)
      WhitespaceHandler.new(ignore_standalone: @ignore_standalone).process(expr)
    end
  end
end
