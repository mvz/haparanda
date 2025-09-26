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

  describe "inline partial loopup" do
    it "finds inline partials as top level elements inside partial block calls" do
      compiler.register_partial("dude", "{{> myPartial }}")
      result =
        compiler
        .compile(
          '{{#> dude}}foo{{qux}}{{#*inline "myPartial"}}bar{{/inline}}{{baz}}{{/dude}}'
        ).call({})
      _(result).must_equal "bar"
    end
  end
end
