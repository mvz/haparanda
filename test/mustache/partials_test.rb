# frozen_string_literal: true

require "test_helper"

describe "partials" do
  let(:compiler) { Haparanda::Compiler.new }
  describe "Basic Behavior" do
    specify "The greater-than operator should expand to the named partial." do
      compiler.register_partial("text", "from partial")
      template = "\"{{>text}}\""
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"from partial\""
    end
  end
  describe "Failed Lookup" do
    specify "The empty string should be used when the named partial is not found." do
      skip "Handlebars raises error if partial is not found"
      template = "\"{{>text}}\""
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "Context" do
    specify "The greater-than operator should operate within the current context." do
      compiler.register_partial("partial", "*{{text}}*")
      template = "\"{{>partial}}\""
      input = {"text" => "content"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"*content*\""
    end
  end
  describe "Recursion" do
    specify "The greater-than operator should properly recurse." do
      compiler.register_partial("node", "{{content}}<{{#nodes}}{{>node}}{{/nodes}}>")
      template = "{{>node}}"
      input = {"content" => "X", "nodes" => [{"content" => "Y", "nodes" => []}]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "X<Y<>>"
    end
  end
  describe "Nested" do
    specify "The greater-than operator should work from within partials." do
      compiler.register_partial("outer", "*{{a}} {{>inner}}*")
      compiler.register_partial("inner", "{{b}}!")
      template = "{{>outer}}"
      input = {"a" => "hello", "b" => "world"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "*hello world!*"
    end
  end
  describe "Surrounding Whitespace" do
    specify "The greater-than operator should not alter surrounding whitespace." do
      compiler.register_partial("partial", "\t|\t")
      template = "| {{>partial}} |"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| \t|\t |"
    end
  end
  describe "Inline Indentation" do
    specify "Whitespace should be left untouched." do
      compiler.register_partial("partial", ">\n>")
      template = "  {{data}}  {{> partial}}\n"
      input = {"data" => "|"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "  |  >\n>\n"
    end
  end
  describe "Standalone Line Endings" do
    specify "\"\\r\\n\" should be considered a newline for standalone tags." do
      compiler.register_partial("partial", ">")
      template = "|\r\n{{>partial}}\r\n|"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|\r\n>|"
    end
  end
  describe "Standalone Without Previous Line" do
    specify "Standalone tags should not require a newline to precede them." do
      compiler.register_partial("partial", ">\n>")
      template = "  {{>partial}}\n>"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "  >\n  >>"
    end
  end
  describe "Standalone Without Newline" do
    specify "Standalone tags should not require a newline to follow them." do
      skip "TODO"
      compiler.register_partial("partial", ">\n>")
      template = ">\n  {{>partial}}"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal ">\n  >\n  >"
    end
  end
  describe "Standalone Indentation" do
    specify "Each line of the partial should be indented before rendering." do
      skip "Handlebars nests the entire response from partials, not just the literals"
      compiler.register_partial("partial", "|\n{{{content}}}\n|\n")
      template = "\\\n {{>partial}}\n/\n"
      input = {"content" => "<\n->"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\\\n |\n <\n->\n |\n/\n"
    end
  end
  describe "Padding Whitespace" do
    specify "Superfluous in-tag whitespace should be ignored." do
      compiler.register_partial("partial", "[]")
      template = "|{{> partial }}|"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|[]|"
    end
  end
end
