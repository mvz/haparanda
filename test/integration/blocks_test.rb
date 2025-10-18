# frozen_string_literal: true

require "test_helper"

describe "blocks" do
  let(:compiler) { Haparanda::Compiler.new }

  describe "context nesting" do
    it "allows lookup in the parent context in compatibilty mode" do
      result = compiler.compile("{{#foo}}{{bar}}{{baz}}{{/foo}}", compat: true)
                       .call({ foo: { bar: "bar" }, baz: "baz" })

      _(result).must_equal "barbaz"
    end
  end

  describe "values lookup" do
    it "does not skip over nil values when iterating over an array" do
      result = compiler.compile("{{#array}}{{@index}}{{.}}{{/array}}")
                       .call({ array: [nil, "foo", nil, "bar"] })

      _(result).must_equal "01foo23bar"
    end

    it "does not skip over nil values when iterating over an array with #each" do
      result = compiler.compile("{{#array}}{{@index}}{{.}}{{/array}}")
                       .call({ array: [nil, "foo", nil, "bar"] })

      _(result).must_equal "01foo23bar"
    end
  end
end
