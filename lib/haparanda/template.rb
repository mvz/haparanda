# frozen_string_literal: true

module Haparanda
  # Callable representation of a handlebars template
  class Template
    def initialize(expr, helpers, partials, **compile_options)
      @expr = expr
      @helpers = helpers
      @partials = partials
      @compile_options = compile_options
    end

    def call(input, helpers: {}, **runtime_options)
      all_helpers = @helpers.merge(helpers)
      if @compile_options[:known_helpers_only]
        keys = @compile_options[:known_helpers]&.keys || []
        all_helpers = all_helpers.slice(*keys)
      end
      # TODO: Change interface of HandlebarsProcessor so it can be instantiated
      # in Template#initialize
      processor = HandlebarsProcessor.new(input,
                                          helpers: all_helpers,
                                          partials: @partials,
                                          **runtime_options)
      processor.apply(@expr)
    end
  end
end
