# frozen_string_literal: true

require "content_combiner"
require "whitespace_handler"

# Process the handlebars AST just to combine subsequent :content items
class HandlebarsCompiler
  def initialize(ignore_standalone: false, **)
    @ignore_standalone = ignore_standalone
  end

  def process(expr)
    expr = ContentCombiner.new.process(expr)
    WhitespaceHandler.new(ignore_standalone: @ignore_standalone).process(expr)
  end
end
