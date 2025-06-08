# frozen_string_literal: true

require_relative "template"

module Haparanda
  # Compile handlebars template to a callable Haparanda::Template object
  class Compiler
    def initialize
      @parser = HandlebarsParser.new
      @helpers = {}
    end

    def compile(text, **compile_options)
      template = parser.parse(text)
      # TODO: Rename to PostProcessor
      post_processor = HandlebarsCompiler.new(**compile_options)
      compiled_template = post_processor.process(template)
      Template.new(compiled_template, @helpers)
    end

    def register_helper(name, &definition)
      @helpers[name.to_sym] = definition
    end

    private

    attr_reader :parser, :post_processor
  end
end
