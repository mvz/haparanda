# frozen_string_literal: true

module Haparanda
  # Callable representation of a handlebars template
  class Template
    def initialize(expr, helpers, partials, log, **compile_options)
      @expr = expr
      @helpers = helpers
      @partials = partials
      @log = log
      @compile_options = compile_options
    end

    def call(input, helpers: {}, data: {})
      all_helpers = @helpers.merge(helpers)
      if @compile_options[:known_helpers_only]
        keys = @compile_options[:known_helpers]&.keys || []
        all_helpers = all_helpers.slice(*keys)
      end
      explicit_partial_context = true if @compile_options[:explicit_partial_context]
      # TODO: Change interface of HandlebarsProcessor so it can be instantiated
      # in Template#initialize
      processor =
        HandlebarsProcessor.new(input,
                                helpers: all_helpers,
                                partials: @partials,
                                log: @log,
                                data: data,
                                explicit_partial_context: explicit_partial_context)
      processor.apply(@expr)
    end
  end
end
