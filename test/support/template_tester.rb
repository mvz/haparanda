# frozen_string_literal: true

require "handlebars_parser"

class TemplateTester
  def initialize(str, spec)
    @str = str
    @spec = spec
    @input = {}
    @helpers = {}
  end

  def withInput(input) # rubocop:disable Naming/MethodName
    @input = input
    self
  end

  def withMessage(message) # rubocop:disable Naming/MethodName
    @message = message
    self
  end

  def withRuntimeOptions(_opts) # rubocop:disable Naming/MethodName
    self
  end

  def withCompileOptions(_opts) # rubocop:disable Naming/MethodName
    self
  end

  def withHelpers(opts) # rubocop:disable Naming/MethodName
    @helpers = opts
    self
  end

  def withHelper(name, helper) # rubocop:disable Naming/MethodName
    @helpers[name.to_sym] = helper
    self
  end

  def toCompileTo(expected) # rubocop:disable Naming/MethodName
    template = HandlebarsParser.new.parse(@str)
    processor = HandlebarsProcessor.new(@input, @helpers)
    actual = processor.apply(template)
    @spec._(actual).must_equal expected, @message
  end

  def toThrow(error, message = nil) # rubocop:disable Naming/MethodName
    @spec.shouldThrow(-> { toCompileTo("") }, error, message)
  end
end
