# frozen_string_literal: true

require "handlebars_parser"
require "whitespace_handler"
require "handlebars_processor"

class TemplateTester
  def initialize(str, spec)
    @str = str
    @spec = spec
    @input = {}
    @helpers = {}
    @runtime_options = {}
  end

  def withInput(input) # rubocop:disable Naming/MethodName
    @input = input
    self
  end

  def withMessage(message) # rubocop:disable Naming/MethodName
    @message = message
    self
  end

  def withRuntimeOptions(opts) # rubocop:disable Naming/MethodName
    @runtime_options = opts
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
    expected = expected.gsub('\n', "\n")
    template = HandlebarsParser.new.parse(@str)
    compiled_template = WhitespaceHandler.new.process(template)
    processor = HandlebarsProcessor.new(@input, @helpers, **@runtime_options)
    actual = processor.apply(compiled_template)
    @spec._(actual).must_equal expected, @message
  end

  def toThrow(error, message = nil) # rubocop:disable Naming/MethodName
    @spec.shouldThrow(-> { toCompileTo("") }, error, message)
  end
end
