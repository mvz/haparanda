# frozen_string_literal: true

require "test_helper"

describe HandlebarsParser do
  let(:parser) { HandlebarsParser.new }

  it "parses content" do
    result = parser.parse "Hello!"

    _(result).must_equal({ type: "ContentStatement", original: ["Hello!"], value: ["Hello!"], loc: 1 })
  end
end
