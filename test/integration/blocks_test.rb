# frozen_string_literal: true

require "test_helper"

describe "blocks" do
  let(:compiler) { Haparanda::Compiler.new }

  describe "context nesting" do
    it "allows lookup in the parent context" do
      result = compiler.compile("{{#foo}}{{bar}}{{baz}}{{/foo}}", compat: true)
                       .call({ foo: { bar: "bar" }, baz: "baz" })

      _(result).must_equal "barbaz"
    end
  end
end
