# frozen_string_literal: true

require "test_helper"

describe "inverted" do
  let(:compiler) { Haparanda::Compiler.new }
  describe "Falsey" do
    specify "Falsey sections should have their contents rendered." do
      template = "\"{{^boolean}}This should be rendered.{{/boolean}}\""
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"This should be rendered.\""
    end
  end
  describe "Truthy" do
    specify "Truthy sections should have their contents omitted." do
      template = "\"{{^boolean}}This should not be rendered.{{/boolean}}\""
      input = {"boolean" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "Null is falsey" do
    specify "Null is falsey." do
      template = "\"{{^null}}This should be rendered.{{/null}}\""
      input = {"null" => nil}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"This should be rendered.\""
    end
  end
  describe "Context" do
    specify "Objects and hashes should behave like truthy values." do
      template = "\"{{^context}}Hi {{name}}.{{/context}}\""
      input = {"context" => {"name" => "Joe"}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "List" do
    specify "Lists should behave like truthy values." do
      template = "\"{{^list}}{{n}}{{/list}}\""
      input = {"list" => [{"n" => 1}, {"n" => 2}, {"n" => 3}]}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\""
    end
  end
  describe "Empty List" do
    specify "Empty lists should behave like falsey values." do
      template = "\"{{^list}}Yay lists!{{/list}}\""
      input = {"list" => []}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Yay lists!\""
    end
  end
  describe "Doubled" do
    specify "Multiple inverted sections per template should be permitted." do
      template = "{{^bool}}\n* first\n{{/bool}}\n* {{two}}\n{{^bool}}\n* third\n{{/bool}}\n"
      input = {"bool" => false, "two" => "second"}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "* first\n* second\n* third\n"
    end
  end
  describe "Nested (Falsey)" do
    specify "Nested falsey sections should have their contents rendered." do
      template = "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"
      input = {"bool" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| A B C D E |"
    end
  end
  describe "Nested (Truthy)" do
    specify "Nested truthy sections should be omitted." do
      template = "| A {{^bool}}B {{^bool}}C{{/bool}} D{{/bool}} E |"
      input = {"bool" => true}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| A  E |"
    end
  end
  describe "Context Misses" do
    specify "Failed context lookups should be considered falsey." do
      template = "[{{^missing}}Cannot find key 'missing'!{{/missing}}]"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "[Cannot find key 'missing'!]"
    end
  end
  describe "Dotted Names - Truthy" do
    specify "Dotted names should be valid for Inverted Section tags." do
      template = "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"\""
      input = {"a" => {"b" => {"c" => true}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"\" == \"\""
    end
  end
  describe "Dotted Names - Falsey" do
    specify "Dotted names should be valid for Inverted Section tags." do
      template = "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""
      input = {"a" => {"b" => {"c" => false}}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Not Here\" == \"Not Here\""
    end
  end
  describe "Dotted Names - Broken Chains" do
    specify "Dotted names that cannot be resolved should be considered falsey." do
      template = "\"{{^a.b.c}}Not Here{{/a.b.c}}\" == \"Not Here\""
      input = {"a" => {}}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "\"Not Here\" == \"Not Here\""
    end
  end
  describe "Surrounding Whitespace" do
    specify "Inverted sections should not alter surrounding whitespace." do
      template = " | {{^boolean}}\t|\t{{/boolean}} | \n"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " | \t|\t | \n"
    end
  end
  describe "Internal Whitespace" do
    specify "Inverted should not alter internal whitespace." do
      template = " | {{^boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " |  \n  | \n"
    end
  end
  describe "Indented Inline Sections" do
    specify "Single-line sections should not alter surrounding whitespace." do
      template = " {{^boolean}}NO{{/boolean}}\n {{^boolean}}WAY{{/boolean}}\n"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal " NO\n WAY\n"
    end
  end
  describe "Standalone Lines" do
    specify "Standalone lines should be removed from the template." do
      template = "| This Is\n{{^boolean}}\n|\n{{/boolean}}\n| A Line\n"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| This Is\n|\n| A Line\n"
    end
  end
  describe "Standalone Indented Lines" do
    specify "Standalone indented lines should be removed from the template." do
      template = "| This Is\n  {{^boolean}}\n|\n  {{/boolean}}\n| A Line\n"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "| This Is\n|\n| A Line\n"
    end
  end
  describe "Standalone Line Endings" do
    specify "\"\\r\\n\" should be considered a newline for standalone tags." do
      template = "|\r\n{{^boolean}}\r\n{{/boolean}}\r\n|"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|\r\n|"
    end
  end
  describe "Standalone Without Previous Line" do
    specify "Standalone tags should not require a newline to precede them." do
      template = "  {{^boolean}}\n^{{/boolean}}\n/"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "^\n/"
    end
  end
  describe "Standalone Without Newline" do
    specify "Standalone tags should not require a newline to follow them." do
      template = "^{{^boolean}}\n/\n  {{/boolean}}"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "^\n/\n"
    end
  end
  describe "Padding" do
    specify "Superfluous in-tag whitespace should be ignored." do
      template = "|{{^ boolean }}={{/ boolean }}|"
      input = {"boolean" => false}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|=|"
    end
  end
end
