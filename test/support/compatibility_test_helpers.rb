# frozen_string_literal: true

require_relative "template_tester"

# Helper methods to make compatibility tests most similar to original
# handlebars-parser and handlebars.js specs.
module CompatibilityTestHelpers
  def equals(act, exp, message = nil)
    exp = exp.gsub('\n', "\n") if exp.is_a? String
    if exp.nil?
      _(act).must_be_nil message
    else
      _(act).must_equal exp, message
    end
  end

  def shouldThrow(function, error, message = nil) # rubocop:disable Naming/MethodName
    exception = _(function).must_raise error
    _(exception.message).must_match message if message
  end

  def expectTemplate(template) # rubocop:disable Naming/MethodName
    template = template.gsub('\n', "\n")
    TemplateTester.new(text: template, compiler: handlebarsEnv, spec: self)
  end

  def handlebarsEnv # rubocop:disable Naming/MethodName
    @handlebarsEnv ||= Haparanda::Compiler.new # rubocop:disable Naming/VariableName
  end
end

Minitest::Test.include CompatibilityTestHelpers
