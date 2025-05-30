# frozen_string_literal: true

module Haparanda
  # Callable representation of a handlebars template
  class Template
    def initialize(expr, helpers)
      @expr = expr
      @helpers = helpers
    end

    def call(input, **runtime_options)
      processor = HandlebarsProcessor.new(input, @helpers, **runtime_options)
      processor.apply(@expr)
    end
  end
end
