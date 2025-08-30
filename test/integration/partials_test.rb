# frozen_string_literal: true

require "test_helper"

describe "partials" do
  let(:compiler) { Haparanda::Compiler.new }

  describe "value lookup" do
    it "does not defer to the parent template's context if a context is given" do
      compiler.register_partial(:qux, "{{foo}}{{bar}}")
      result = compiler.compile("{{>qux baz}}")
                       .call({ foo: "foo", baz: { bar: "bar" } })

      _(result).must_equal "bar"
    end
  end
end
