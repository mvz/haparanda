# frozen_string_literal: true

require "test_helper"

describe "sections" do
  let(:compiler) { Haparanda::Compiler.new }
  describe "Truthy" do
    specify "Truthy sections should have their contents rendered." do
      template = "\"{{#boolean}}This should be rendered.{{/boolean}}\""
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"This should be rendered.\""
    end
  end
  describe "Falsey" do
    specify "Falsey sections should have their contents omitted." do
      template = "\"{{#boolean}}This should not be rendered.{{/boolean}}\""
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "Null is falsey" do
    specify "Null is falsey." do
      template = "\"{{#null}}This should not be rendered.{{/null}}\""
      input = {"null" => nil}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "Context" do
    specify "Objects and hashes should be pushed onto the context stack." do
      template = "\"{{#context}}Hi {{name}}.{{/context}}\""
      input = {"context" => {"name" => "Joe"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Hi Joe.\""
    end
  end
  describe "Parent contexts" do
    specify "Names missing in the current context are looked up in the stack." do
      template = "\"{{#sec}}{{a}}, {{b}}, {{c.d}}{{/sec}}\""
      input = {"a" => "foo", "b" => "wrong", "sec" => {"b" => "bar"}, "c" => {"d" => "baz"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"foo, bar, baz\""
    end
  end
  describe "Variable test" do
    specify "Non-false sections have their value at the top of context,\naccessible as {{.}} or through the parent context. This gives\na simple way to display content conditionally if a variable exists.\n" do
      template = "\"{{#foo}}{{.}} is {{foo}}{{/foo}}\""
      input = {"foo" => "bar"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"bar is bar\""
    end
  end
  describe "List Contexts" do
    specify "All elements on the context stack should be accessible within lists." do
      template = "{{#tops}}{{#middles}}{{tname.lower}}{{mname}}.{{#bottoms}}{{tname.upper}}{{mname}}{{bname}}.{{/bottoms}}{{/middles}}{{/tops}}"
      input = {"tops" => [{"tname" => {"upper" => "A", "lower" => "a"}, "middles" => [{"mname" => "1", "bottoms" => [{"bname" => "x"}, {"bname" => "y"}]}]}]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "a1.A1x.A1y."
    end
  end
  describe "Deeply Nested Contexts" do
    specify "All elements on the context stack should be accessible." do
      template = "{{#a}}\n{{one}}\n{{#b}}\n{{one}}{{two}}{{one}}\n{{#c}}\n{{one}}{{two}}{{three}}{{two}}{{one}}\n{{#d}}\n{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}\n{{#five}}\n{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}\n{{one}}{{two}}{{three}}{{four}}{{.}}6{{.}}{{four}}{{three}}{{two}}{{one}}\n{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}\n{{/five}}\n{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}\n{{/d}}\n{{one}}{{two}}{{three}}{{two}}{{one}}\n{{/c}}\n{{one}}{{two}}{{one}}\n{{/b}}\n{{one}}\n{{/a}}\n"
      input = {"a" => {"one" => 1}, "b" => {"two" => 2}, "c" => {"three" => 3, "d" => {"four" => 4, "five" => 5}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "1\n121\n12321\n1234321\n123454321\n12345654321\n123454321\n1234321\n12321\n121\n1\n"
    end
  end
  describe "List" do
    specify "Lists should be iterated; list items should visit the context stack." do
      template = "\"{{#list}}{{item}}{{/list}}\""
      input = {"list" => [{"item" => 1}, {"item" => 2}, {"item" => 3}]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"123\""
    end
  end
  describe "Empty List" do
    specify "Empty lists should behave like falsey values." do
      template = "\"{{#list}}Yay lists!{{/list}}\""
      input = {"list" => []}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "Doubled" do
    specify "Multiple sections per template should be permitted." do
      template = "{{#bool}}\n* first\n{{/bool}}\n* {{two}}\n{{#bool}}\n* third\n{{/bool}}\n"
      input = {"bool" => true, "two" => "second"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "* first\n* second\n* third\n"
    end
  end
  describe "Nested (Truthy)" do
    specify "Nested truthy sections should have their contents rendered." do
      template = "| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |"
      input = {"bool" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| A B C D E |"
    end
  end
  describe "Nested (Falsey)" do
    specify "Nested falsey sections should be omitted." do
      template = "| A {{#bool}}B {{#bool}}C{{/bool}} D{{/bool}} E |"
      input = {"bool" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| A  E |"
    end
  end
  describe "Context Misses" do
    specify "Failed context lookups should be considered falsey." do
      template = "[{{#missing}}Found key 'missing'!{{/missing}}]"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "[]"
    end
  end
  describe "Implicit Iterator - String" do
    specify "Implicit iterators should directly interpolate strings." do
      template = "\"{{#list}}({{.}}){{/list}}\""
      input = {"list" => ["a", "b", "c", "d", "e"]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(a)(b)(c)(d)(e)\""
    end
  end
  describe "Implicit Iterator - Integer" do
    specify "Implicit iterators should cast integers to strings and interpolate." do
      template = "\"{{#list}}({{.}}){{/list}}\""
      input = {"list" => [1, 2, 3, 4, 5]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(1)(2)(3)(4)(5)\""
    end
  end
  describe "Implicit Iterator - Decimal" do
    specify "Implicit iterators should cast decimals to strings and interpolate." do
      template = "\"{{#list}}({{.}}){{/list}}\""
      input = {"list" => [1.1, 2.2, 3.3, 4.4, 5.5]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(1.1)(2.2)(3.3)(4.4)(5.5)\""
    end
  end
  describe "Implicit Iterator - Array" do
    specify "Implicit iterators should allow iterating over nested arrays." do
      template = "\"{{#list}}({{#.}}{{.}}{{/.}}){{/list}}\""
      input = {"list" => [[1, 2, 3], ["a", "b", "c"]]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(123)(abc)\""
    end
  end
  describe "Implicit Iterator - HTML Escaping" do
    specify "Implicit iterators with basic interpolation should be HTML escaped." do
      template = "\"{{#list}}({{.}}){{/list}}\""
      input = {"list" => ["&", "\"", "<", ">"]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(&amp;)(&quot;)(&lt;)(&gt;)\""
    end
  end
  describe "Implicit Iterator - Triple mustache" do
    specify "Implicit iterators in triple mustache should interpolate without HTML escaping." do
      template = "\"{{#list}}({{{.}}}){{/list}}\""
      input = {"list" => ["&", "\"", "<", ">"]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(&)(\")(<)(>)\""
    end
  end
  describe "Implicit Iterator - Ampersand" do
    specify "Implicit iterators in an Ampersand tag should interpolate without HTML escaping." do
      template = "\"{{#list}}({{&.}}){{/list}}\""
      input = {"list" => ["&", "\"", "<", ">"]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(&)(\")(<)(>)\""
    end
  end
  describe "Implicit Iterator - Root-level" do
    specify "Implicit iterators should work on root-level lists." do
      template = "\"{{#.}}({{value}}){{/.}}\""
      input = [{"value" => "a"}, {"value" => "b"}]
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"(a)(b)\""
    end
  end
  describe "Dotted Names - Truthy" do
    specify "Dotted names should be valid for Section tags." do
      template = "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"Here\""
      input = {"a" => {"b" => {"c" => true}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Here\" == \"Here\""
    end
  end
  describe "Dotted Names - Falsey" do
    specify "Dotted names should be valid for Section tags." do
      template = "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\""
      input = {"a" => {"b" => {"c" => false}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\" == \"\""
    end
  end
  describe "Dotted Names - Broken Chains" do
    specify "Dotted names that cannot be resolved should be considered falsey." do
      template = "\"{{#a.b.c}}Here{{/a.b.c}}\" == \"\""
      input = {"a" => {}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\" == \"\""
    end
  end
  describe "Surrounding Whitespace" do
    specify "Sections should not alter surrounding whitespace." do
      template = " | {{#boolean}}\t|\t{{/boolean}} | \n"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " | \t|\t | \n"
    end
  end
  describe "Internal Whitespace" do
    specify "Sections should not alter internal whitespace." do
      template = " | {{#boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " |  \n  | \n"
    end
  end
  describe "Indented Inline Sections" do
    specify "Single-line sections should not alter surrounding whitespace." do
      template = " {{#boolean}}YES{{/boolean}}\n {{#boolean}}GOOD{{/boolean}}\n"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " YES\n GOOD\n"
    end
  end
  describe "Standalone Lines" do
    specify "Standalone lines should be removed from the template." do
      template = "| This Is\n{{#boolean}}\n|\n{{/boolean}}\n| A Line\n"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| This Is\n|\n| A Line\n"
    end
  end
  describe "Indented Standalone Lines" do
    specify "Indented standalone lines should be removed from the template." do
      template = "| This Is\n  {{#boolean}}\n|\n  {{/boolean}}\n| A Line\n"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| This Is\n|\n| A Line\n"
    end
  end
  describe "Standalone Line Endings" do
    specify "\"\\r\\n\" should be considered a newline for standalone tags." do
      skip "TODO"
      template = "|\r\n{{#boolean}}\r\n{{/boolean}}\r\n|"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|\r\n|"
    end
  end
  describe "Standalone Without Previous Line" do
    specify "Standalone tags should not require a newline to precede them." do
      skip "TODO"
      template = "  {{#boolean}}\n\#{{/boolean}}\n/"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "#\n/"
    end
  end
  describe "Standalone Without Newline" do
    specify "Standalone tags should not require a newline to follow them." do
      skip "TODO"
      template = "\#{{#boolean}}\n/\n  {{/boolean}}"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "#\n/\n"
    end
  end
  describe "Padding" do
    specify "Superfluous in-tag whitespace should be ignored." do
      template = "|{{# boolean }}={{/ boolean }}|"
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|=|"
    end
  end
end
