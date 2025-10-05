# frozen_string_literal: true

require "test_helper"

describe "interpolation" do
  let(:compiler) { Haparanda::Compiler.new }
  describe "No Interpolation" do
    specify "Mustache-free templates should render as-is." do
      template = "Hello from {Mustache}!\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Hello from {Mustache}!\n"
    end
  end
  describe "Basic Interpolation" do
    specify "Unadorned tags should interpolate content into the template." do
      template = "Hello, {{subject}}!\n"
      input = {"subject" => "world"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Hello, world!\n"
    end
  end
  describe "No Re-interpolation" do
    specify "Interpolated tag output should not be re-interpolated." do
      template = "{{template}}: {{planet}}"
      input = {"template" => "{{planet}}", "planet" => "Earth"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "{{planet}}: Earth"
    end
  end
  describe "HTML Escaping" do
    specify "Basic interpolation should be HTML escaped." do
      template = "These characters should be HTML escaped: {{forbidden}}\n"
      input = {"forbidden" => "& \" < >"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n"
    end
  end
  describe "Triple Mustache" do
    specify "Triple mustaches should interpolate without HTML escaping." do
      template = "These characters should not be HTML escaped: {{{forbidden}}}\n"
      input = {"forbidden" => "& \" < >"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "These characters should not be HTML escaped: & \" < >\n"
    end
  end
  describe "Ampersand" do
    specify "Ampersand should interpolate without HTML escaping." do
      template = "These characters should not be HTML escaped: {{&forbidden}}\n"
      input = {"forbidden" => "& \" < >"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "These characters should not be HTML escaped: & \" < >\n"
    end
  end
  describe "Basic Integer Interpolation" do
    specify "Integers should interpolate seamlessly." do
      template = "\"{{mph}} miles an hour!\""
      input = {"mph" => 85}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"85 miles an hour!\""
    end
  end
  describe "Triple Mustache Integer Interpolation" do
    specify "Integers should interpolate seamlessly." do
      template = "\"{{{mph}}} miles an hour!\""
      input = {"mph" => 85}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"85 miles an hour!\""
    end
  end
  describe "Ampersand Integer Interpolation" do
    specify "Integers should interpolate seamlessly." do
      template = "\"{{&mph}} miles an hour!\""
      input = {"mph" => 85}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"85 miles an hour!\""
    end
  end
  describe "Basic Decimal Interpolation" do
    specify "Decimals should interpolate seamlessly with proper significance." do
      template = "\"{{power}} jiggawatts!\""
      input = {"power" => 1.21}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"1.21 jiggawatts!\""
    end
  end
  describe "Triple Mustache Decimal Interpolation" do
    specify "Decimals should interpolate seamlessly with proper significance." do
      template = "\"{{{power}}} jiggawatts!\""
      input = {"power" => 1.21}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"1.21 jiggawatts!\""
    end
  end
  describe "Ampersand Decimal Interpolation" do
    specify "Decimals should interpolate seamlessly with proper significance." do
      template = "\"{{&power}} jiggawatts!\""
      input = {"power" => 1.21}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"1.21 jiggawatts!\""
    end
  end
  describe "Basic Null Interpolation" do
    specify "Nulls should interpolate as the empty string." do
      template = "I ({{cannot}}) be seen!"
      input = {"cannot" => nil}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "I () be seen!"
    end
  end
  describe "Triple Mustache Null Interpolation" do
    specify "Nulls should interpolate as the empty string." do
      template = "I ({{{cannot}}}) be seen!"
      input = {"cannot" => nil}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "I () be seen!"
    end
  end
  describe "Ampersand Null Interpolation" do
    specify "Nulls should interpolate as the empty string." do
      template = "I ({{&cannot}}) be seen!"
      input = {"cannot" => nil}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "I () be seen!"
    end
  end
  describe "Basic Context Miss Interpolation" do
    specify "Failed context lookups should default to empty strings." do
      template = "I ({{cannot}}) be seen!"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "I () be seen!"
    end
  end
  describe "Triple Mustache Context Miss Interpolation" do
    specify "Failed context lookups should default to empty strings." do
      template = "I ({{{cannot}}}) be seen!"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "I () be seen!"
    end
  end
  describe "Ampersand Context Miss Interpolation" do
    specify "Failed context lookups should default to empty strings." do
      template = "I ({{&cannot}}) be seen!"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "I () be seen!"
    end
  end
  describe "Dotted Names - Basic Interpolation" do
    specify "Dotted names should be considered a form of shorthand for sections." do
      template = "\"{{person.name}}\" == \"{{#person}}{{name}}{{/person}}\""
      input = {"person" => {"name" => "Joe"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Joe\" == \"Joe\""
    end
  end
  describe "Dotted Names - Triple Mustache Interpolation" do
    specify "Dotted names should be considered a form of shorthand for sections." do
      template = "\"{{{person.name}}}\" == \"{{#person}}{{{name}}}{{/person}}\""
      input = {"person" => {"name" => "Joe"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Joe\" == \"Joe\""
    end
  end
  describe "Dotted Names - Ampersand Interpolation" do
    specify "Dotted names should be considered a form of shorthand for sections." do
      template = "\"{{&person.name}}\" == \"{{#person}}{{&name}}{{/person}}\""
      input = {"person" => {"name" => "Joe"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Joe\" == \"Joe\""
    end
  end
  describe "Dotted Names - Arbitrary Depth" do
    specify "Dotted names should be functional to any level of nesting." do
      template = "\"{{a.b.c.d.e.name}}\" == \"Phil\""
      input = {"a" => {"b" => {"c" => {"d" => {"e" => {"name" => "Phil"}}}}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Phil\" == \"Phil\""
    end
  end
  describe "Dotted Names - Broken Chains" do
    specify "Any falsey value prior to the last part of the name should yield ''." do
      template = "\"{{a.b.c}}\" == \"\""
      input = {"a" => {}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\" == \"\""
    end
  end
  describe "Dotted Names - Broken Chain Resolution" do
    specify "Each part of a dotted name should resolve only against its parent." do
      template = "\"{{a.b.c.name}}\" == \"\""
      input = {"a" => {"b" => {}}, "c" => {"name" => "Jim"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\" == \"\""
    end
  end
  describe "Dotted Names - Initial Resolution" do
    specify "The first part of a dotted name should resolve as any other name." do
      template = "\"{{#a}}{{b.c.d.e.name}}{{/a}}\" == \"Phil\""
      input = {"a" => {"b" => {"c" => {"d" => {"e" => {"name" => "Phil"}}}}}, "b" => {"c" => {"d" => {"e" => {"name" => "Wrong"}}}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Phil\" == \"Phil\""
    end
  end
  describe "Dotted Names - Context Precedence" do
    specify "Dotted names should be resolved against former resolutions." do
      template = "{{#a}}{{b.c}}{{/a}}"
      input = {"a" => {"b" => {}}, "b" => {"c" => "ERROR"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal ""
    end
  end
  describe "Dotted Names are never single keys" do
    specify "Dotted names shall not be parsed as single, atomic keys" do
      template = "{{a.b}}"
      input = {"a.b" => "c"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal ""
    end
  end
  describe "Dotted Names - No Masking" do
    specify "Dotted Names in a given context are unvavailable due to dot splitting" do
      template = "{{a.b}}"
      input = {"a.b" => "c", "a" => {"b" => "d"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "d"
    end
  end
  describe "Implicit Iterators - Basic Interpolation" do
    specify "Unadorned tags should interpolate content into the template." do
      template = "Hello, {{.}}!\n"
      input = "world"
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Hello, world!\n"
    end
  end
  describe "Implicit Iterators - HTML Escaping" do
    specify "Basic interpolation should be HTML escaped." do
      template = "These characters should be HTML escaped: {{.}}\n"
      input = "& \" < >"
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "These characters should be HTML escaped: &amp; &quot; &lt; &gt;\n"
    end
  end
  describe "Implicit Iterators - Triple Mustache" do
    specify "Triple mustaches should interpolate without HTML escaping." do
      template = "These characters should not be HTML escaped: {{{.}}}\n"
      input = "& \" < >"
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "These characters should not be HTML escaped: & \" < >\n"
    end
  end
  describe "Implicit Iterators - Ampersand" do
    specify "Ampersand should interpolate without HTML escaping." do
      template = "These characters should not be HTML escaped: {{&.}}\n"
      input = "& \" < >"
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "These characters should not be HTML escaped: & \" < >\n"
    end
  end
  describe "Implicit Iterators - Basic Integer Interpolation" do
    specify "Integers should interpolate seamlessly." do
      template = "\"{{.}} miles an hour!\""
      input = 85
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"85 miles an hour!\""
    end
  end
  describe "Interpolation - Surrounding Whitespace" do
    specify "Interpolation should not alter surrounding whitespace." do
      template = "| {{string}} |"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| --- |"
    end
  end
  describe "Triple Mustache - Surrounding Whitespace" do
    specify "Interpolation should not alter surrounding whitespace." do
      template = "| {{{string}}} |"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| --- |"
    end
  end
  describe "Ampersand - Surrounding Whitespace" do
    specify "Interpolation should not alter surrounding whitespace." do
      template = "| {{&string}} |"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| --- |"
    end
  end
  describe "Interpolation - Standalone" do
    specify "Standalone interpolation should not alter surrounding whitespace." do
      template = "  {{string}}\n"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "  ---\n"
    end
  end
  describe "Triple Mustache - Standalone" do
    specify "Standalone interpolation should not alter surrounding whitespace." do
      template = "  {{{string}}}\n"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "  ---\n"
    end
  end
  describe "Ampersand - Standalone" do
    specify "Standalone interpolation should not alter surrounding whitespace." do
      template = "  {{&string}}\n"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "  ---\n"
    end
  end
  describe "Interpolation With Padding" do
    specify "Superfluous in-tag whitespace should be ignored." do
      template = "|{{ string }}|"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|---|"
    end
  end
  describe "Triple Mustache With Padding" do
    specify "Superfluous in-tag whitespace should be ignored." do
      template = "|{{{ string }}}|"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|---|"
    end
  end
  describe "Ampersand With Padding" do
    specify "Superfluous in-tag whitespace should be ignored." do
      template = "|{{& string }}|"
      input = {"string" => "---"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|---|"
    end
  end
end
