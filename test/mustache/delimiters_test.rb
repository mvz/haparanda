# frozen_string_literal: true

require "test_helper"

describe "delimiters" do
  let(:compiler) { Haparanda::Compiler.new }
  describe "Pair Behavior" do
    specify "The equals sign (used on both sides) should permit delimiter changes." do
      skip "Handlebars does not support alternative delimiters"
      template = "{{=<% %>=}}(<%text%>)"
      input = {"text" => "Hey!"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "(Hey!)"
    end
  end
  describe "Special Characters" do
    specify "Characters with special meaning regexen should be valid delimiters." do
      skip "Handlebars does not support alternative delimiters"
      template = "({{=[ ]=}}[text])"
      input = {"text" => "It worked!"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "(It worked!)"
    end
  end
  describe "Sections" do
    specify "Delimiters set outside sections should persist." do
      skip "Handlebars does not support alternative delimiters"
      template = "[\n{{#section}}\n  {{data}}\n  |data|\n{{/section}}\n\n{{= | | =}}\n|#section|\n  {{data}}\n  |data|\n|/section|\n]\n"
      input = {"section" => true, "data" => "I got interpolated."}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "[\n  I got interpolated.\n  |data|\n\n  {{data}}\n  I got interpolated.\n]\n"
    end
  end
  describe "Inverted Sections" do
    specify "Delimiters set outside inverted sections should persist." do
      skip "Handlebars does not support alternative delimiters"
      template = "[\n{{^section}}\n  {{data}}\n  |data|\n{{/section}}\n\n{{= | | =}}\n|^section|\n  {{data}}\n  |data|\n|/section|\n]\n"
      input = {"section" => false, "data" => "I got interpolated."}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "[\n  I got interpolated.\n  |data|\n\n  {{data}}\n  I got interpolated.\n]\n"
    end
  end
  describe "Partial Inheritence" do
    specify "Delimiters set in a parent template should not affect a partial." do
      skip "Handlebars does not support alternative delimiters"
      compiler.register_partial("include", ".{{value}}.")
      template = "[ {{>include}} ]\n{{= | | =}}\n[ |>include| ]\n"
      input = {"value" => "yes"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "[ .yes. ]\n[ .yes. ]\n"
    end
  end
  describe "Post-Partial Behavior" do
    specify "Delimiters set in a partial should not affect the parent template." do
      skip "Handlebars does not support alternative delimiters"
      compiler.register_partial("include", ".{{value}}. {{= | | =}} .|value|.")
      template = "[ {{>include}} ]\n[ .{{value}}.  .|value|. ]\n"
      input = {"value" => "yes"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "[ .yes.  .yes. ]\n[ .yes.  .|value|. ]\n"
    end
  end
  describe "Surrounding Whitespace" do
    specify "Surrounding whitespace should be left untouched." do
      skip "Handlebars does not support alternative delimiters"
      template = "| {{=@ @=}} |"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|  |"
    end
  end
  describe "Outlying Whitespace (Inline)" do
    specify "Whitespace should be left untouched." do
      skip "Handlebars does not support alternative delimiters"
      template = " | {{=@ @=}}\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " | \n"
    end
  end
  describe "Standalone Tag" do
    specify "Standalone lines should be removed from the template." do
      skip "Handlebars does not support alternative delimiters"
      template = "Begin.\n{{=@ @=}}\nEnd.\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Begin.\nEnd.\n"
    end
  end
  describe "Indented Standalone Tag" do
    specify "Indented standalone lines should be removed from the template." do
      skip "Handlebars does not support alternative delimiters"
      template = "Begin.\n  {{=@ @=}}\nEnd.\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Begin.\nEnd.\n"
    end
  end
  describe "Standalone Line Endings" do
    specify "\"\\r\\n\" should be considered a newline for standalone tags." do
      skip "Handlebars does not support alternative delimiters"
      template = "|\r\n{{= @ @ =}}\r\n|"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|\r\n|"
    end
  end
  describe "Standalone Without Previous Line" do
    specify "Standalone tags should not require a newline to precede them." do
      skip "Handlebars does not support alternative delimiters"
      template = "  {{=@ @=}}\n="
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "="
    end
  end
  describe "Standalone Without Newline" do
    specify "Standalone tags should not require a newline to follow them." do
      skip "Handlebars does not support alternative delimiters"
      template = "=\n  {{=@ @=}}"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "=\n"
    end
  end
  describe "Pair with Padding" do
    specify "Superfluous in-tag whitespace should be ignored." do
      skip "Handlebars does not support alternative delimiters"
      template = "|{{= @   @ =}}|"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "||"
    end
  end
end
