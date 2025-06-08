# frozen_string_literal: true

module Haparanda
  # Callable representation of a handlebars template
  class Template
    def initialize(expr, helpers)
      @expr = expr
      @helpers = helpers
    end

    def call(input, helpers: {}, **runtime_options)
      # TODO: Change interface of HandlebarsProcessor so it can be instantiated
      # in Template#initialize
      processor = HandlebarsProcessor.new(input, @helpers.merge(helpers), **runtime_options)
      processor.apply(@expr)
    end
  end
end
