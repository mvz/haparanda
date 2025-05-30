# frozen_string_literal: true

require_relative "template"

module Haparanda
  # Compile handlebars template to a callable Haparanda::Template object
  class Compiler
    def initialize(**compile_options)
      @parser = HandlebarsParser.new
      # TODO: Rename to PostProcessor
      @post_processor = HandlebarsCompiler.new(**compile_options)
      @helpers = {}
    end

    def compile(text)
      template = parser.parse(text)
      compiled_template = post_processor.process(template)
      Template.new(compiled_template, @helpers)
    end

    def register_helper(name, &definition)
      @helpers[name] = definition
    end

    private

    attr_reader :parser, :post_processor
  end
end
