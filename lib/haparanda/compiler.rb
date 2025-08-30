# frozen_string_literal: true

require "logger"
require_relative "template"
require_relative "post_processor"

module Haparanda
  # Compile handlebars template to a callable Haparanda::Template object
  class Compiler
    def initialize
      @parser = HandlebarsParser.new
      @helpers = {}
      @partials = {}
      @log = nil
    end

    def compile(text, **compile_options)
      ast = template_to_ast text, **compile_options
      Template.new(ast, @helpers, @partials, @log, **compile_options)
    end

    def register_helper(name, &definition)
      @helpers[name.to_sym] = definition
    end

    def unregister_helper(name)
      @helpers.delete(name.to_sym)
    end

    def get_helper(name)
      @helpers[name.to_sym]
    end

    def register_partial(name, content)
      @partials[name.to_s] = template_to_ast(content)
    end

    attr_accessor :log

    private

    def template_to_ast(text, **compile_options)
      template = parser.parse(text)
      post_processor = PostProcessor.new(**compile_options)
      post_processor.process(template)
    end

    attr_reader :parser, :post_processor
  end
end
