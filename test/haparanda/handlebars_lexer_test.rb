# frozen_string_literal: true

require "test_helper"

describe Haparanda::HandlebarsLexer do
  let(:lexer) { Haparanda::HandlebarsLexer.new }

  it "lexes content" do
    result = lexer.scan "Hello!"

    _(result).must_equal [[:CONTENT, "Hello!"]]
  end
end
