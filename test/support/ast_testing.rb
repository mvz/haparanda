# frozen_string_literal: true

module AstTesting
  # Helper methods to make assertions most similar to original
  # handlebars-parser test assertions.
  def equals(act, exp)
    exp = exp.gsub('\n', "\n")
    _(act).must_equal exp
  end

  def astFor(str) # rubocop:disable Naming/MethodName
    str = str.gsub('\n', "\n")
    result = parser.parse str
    PrintingProcessor.new.print(result)
  end

  def shouldThrow(function, error, message = nil) # rubocop:disable Naming/MethodName
    exception = _(function).must_raise error
    _(exception.message).must_match message if message
  end
end

Minitest::Test.include AstTesting
