# frozen_string_literal: true

module Haparanda
  # Callable representation of a handlebars template
  class Template
    def initialize(expr, helpers, partials)
      @expr = expr
      @helpers = helpers
      @partials = partials
    end

    def call(input, helpers: {}, **runtime_options)
      # TODO: Change interface of HandlebarsProcessor so it can be instantiated
      # in Template#initialize
      processor = HandlebarsProcessor.new(input,
                                          helpers: @helpers.merge(helpers),
                                          partials: @partials,
                                          **runtime_options)
      processor.apply(@expr)
    end
  end
end
