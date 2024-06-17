# frozen_string_literal: true

require "test_helper"

describe HandlebarsParser do
  let(:parser) { HandlebarsParser.new }

  it "parses content" do
    result = parser.parse "Hello!"

    _(result).must_equal(s(:statements, s(:content, "Hello!")))
  end
end
