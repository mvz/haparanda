# frozen_string_literal: true

require_relative "template_tester"

# Helper methods to make compatibility tests most similar to original
# handlebars-parser and handlebars.js specs.
module CompatibilityTestHelpers
  def equals(act, exp)
    exp = exp.gsub('\n', "\n")
    _(act).must_equal exp
  end

  def shouldThrow(function, error, message = nil) # rubocop:disable Naming/MethodName
    exception = _(function).must_raise error
    _(exception.message).must_match message if message
  end

  def expectTemplate(template) # rubocop:disable Naming/MethodName
    template = template.gsub('\n', "\n")
    TemplateTester.new(template, self)
  end
end

Minitest::Test.include CompatibilityTestHelpers
