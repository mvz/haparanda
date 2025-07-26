# frozen_string_literal: true

require "haparanda/handlebars_parser"
require "haparanda/whitespace_handler"
require "haparanda/handlebars_processor"

class TemplateTester
  def initialize(text:, compiler:, spec:)
    @compiler = compiler
    @text = text
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

  def withPartials(partials) # rubocop:disable Naming/MethodName
    partials.each do |name, content|
      @compiler.register_partial(name, content)
    end
    self
  end

  def withPartial(name, content) # rubocop:disable Naming/MethodName
    @compiler.register_partial(name, content)
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
    compiled_template = @compiler.compile(@text, **@compile_options)
    compiled_template.call(@input, helpers: @helpers, **@runtime_options)
  end

  def underscore_opts(opts)
    opts.transform_keys do |k|
      k.to_s.gsub(/[A-Z]/) { |a| "_#{a.downcase}" }.to_sym
    end
  end
end
