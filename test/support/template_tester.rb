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
    @compile_options = {}
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

  def withCompileOptions(opts) # rubocop:disable Naming/MethodName
    @compile_options = underscore_opts opts
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
    actual = compile_and_process_template
    _(actual).must_equal expected, @message
  end

  def toThrow(error, message = nil) # rubocop:disable Naming/MethodName
    exception = _(-> { compile_and_process_template }).must_raise error
    _(exception.message).must_match message if message
  end

  private

  def _(actual)
    @spec.expect(actual)
  end

  def compile_and_process_template
    template = HandlebarsParser.new.parse(@str)
    compiled_template = HandlebarsCompiler.new(**@compile_options).process(template)
    processor = HandlebarsProcessor.new(@input, @helpers, **@runtime_options)
    processor.apply(compiled_template)
  end

  def underscore_opts(opts)
    opts.transform_keys do |k|
      k.to_s.gsub(/[A-Z]/) { |a| "_#{a.downcase}" }.to_sym
    end
  end
end
