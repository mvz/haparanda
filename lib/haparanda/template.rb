# frozen_string_literal: true

require_relative "parser"

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

    def call(input, helpers: {}, partials: {}, data: {})
      all_helpers = @helpers.merge(helpers)
      partials.transform_values! { parse_partial(_1) }
      all_partials = @partials.merge(partials)
      if @compile_options[:known_helpers_only]
        keys = @compile_options[:known_helpers]&.keys || []
        all_helpers = all_helpers.slice(*keys)
      end
      explicit_partial_context = true if @compile_options[:explicit_partial_context]
      compat = true if @compile_options[:compat]
      no_escape = true if @compile_options[:no_escape]
      # TODO: Change interface of HandlebarsProcessor so it can be instantiated
      # in Template#initialize
      processor =
        HandlebarsProcessor.new(input,
                                helpers: all_helpers,
                                partials: all_partials,
                                log: @log,
                                data: data,
                                compat: compat,
                                explicit_partial_context: explicit_partial_context,
                                no_escape: no_escape)
      processor.apply(@expr)
    end

    private

    def parse_partial(partial)
      return partial if partial.respond_to? :call

      Parser.new(**@compile_options).parse(partial)
    end
  end
end
