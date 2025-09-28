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

    it "cannot look up values outside a nested context" do
      compiler.register_partial(:dude, "{{name}} ({{url}}) {{root}} ")
      template = compiler.compile("Dudes: {{#dudes}}{{> dude}}{{/dudes}}")
      result = template.call({
                               root: "yes",
                               dudes: [
                                 { name: "Yehuda", url: "http://yehuda" },
                                 { name: "Alan", url: "http://alan" }
                               ]
                             })
      _(result).must_equal "Dudes: Yehuda (http://yehuda)  Alan (http://alan)  "
    end

    it "cannot look up values outside custom context" do
      compiler.register_partial(:dude, "{{name}} ({{url}}) {{root}} ")
      template = compiler.compile("Dudes: {{#dudes}}{{> dude \"test\"}}{{/dudes}}")
      result = template.call({
                               root: "yes",
                               dudes: [
                                 { name: "Yehuda", url: "http://yehuda" },
                                 { name: "Alan", url: "http://alan" }
                               ]
                             })
      _(result).must_equal "Dudes:  ()   ()  "
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
