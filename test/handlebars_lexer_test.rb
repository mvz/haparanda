# frozen_string_literal: true

require "test_helper"

describe HandlebarsLexer do
  let(:lexer) { HandlebarsLexer.new }

  it "lexes content" do
    result = lexer.scan "Hello!"

    _(result).must_equal [[:CONTENT, "Hello!"]]
  end
end
