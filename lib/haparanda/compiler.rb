# frozen_string_literal: true

require "logger"
require_relative "template"
require_relative "parser"

module Haparanda
  # Compile handlebars template to a callable Haparanda::Template object
  class Compiler
    def initialize
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

    def register_helpers(**helpers)
      helpers.each do |name, definition|
        register_helper(name, &definition)
      end
    end

    def unregister_helper(name)
      @helpers.delete(name.to_sym)
    end

    def get_helper(name)
      @helpers[name.to_sym]
    end

    def register_partial(name, content)
      unless content
        raise "Attempting to register a partial called \"#{name}\" as #{content.inspect}"
      end

      @partials[name.to_s] = template_to_ast(content)
    end

    def unregister_partial(name)
      @partials.delete(name.to_s)
    end

    def get_partial(name)
      @partials[name.to_s]
    end

    attr_accessor :log

    private

    def template_to_ast(text, **compile_options)
      Parser.new(**compile_options).parse(text)
    end
  end
end
