# frozen_string_literal: true

require "test_helper"

describe "comments" do
  let(:compiler) { Haparanda::Compiler.new }
  describe "Inline" do
    specify "Comment blocks should be removed from the template." do
      template = "12345{{! Comment Block! }}67890"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "1234567890"
    end
  end
  describe "Multiline" do
    specify "Multiline comments should be permitted." do
      template = "12345{{!\n  This is a\n  multi-line comment...\n}}67890\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "1234567890\n"
    end
  end
  describe "Standalone" do
    specify "All standalone comment lines should be removed." do
      template = "Begin.\n{{! Comment Block! }}\nEnd.\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Begin.\nEnd.\n"
    end
  end
  describe "Indented Standalone" do
    specify "All standalone comment lines should be removed." do
      template = "Begin.\n  {{! Indented Comment Block! }}\nEnd.\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Begin.\nEnd.\n"
    end
  end
  describe "Standalone Line Endings" do
    specify "\"\\r\\n\" should be considered a newline for standalone tags." do
      template = "|\r\n{{! Standalone Comment }}\r\n|"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "|\r\n|"
    end
  end
  describe "Standalone Without Previous Line" do
    specify "Standalone tags should not require a newline to precede them." do
      skip "TODO"
      template = "  {{! I'm Still Standalone }}\n!"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "!"
    end
  end
  describe "Standalone Without Newline" do
    specify "Standalone tags should not require a newline to follow them." do
      skip "TODO"
      template = "!\n  {{! I'm Still Standalone }}"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "!\n"
    end
  end
  describe "Multiline Standalone" do
    specify "All standalone comment lines should be removed." do
      template = "Begin.\n{{!\nSomething's going on here...\n}}\nEnd.\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Begin.\nEnd.\n"
    end
  end
  describe "Indented Multiline Standalone" do
    specify "All standalone comment lines should be removed." do
      template = "Begin.\n  {{!\n    Something's going on here...\n  }}\nEnd.\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "Begin.\nEnd.\n"
    end
  end
  describe "Indented Inline" do
    specify "Inline comments should not strip whitespace" do
      template = "  12 {{! 34 }}\n"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "  12 \n"
    end
  end
  describe "Surrounding Whitespace" do
    specify "Comment removal should preserve surrounding whitespace." do
      template = "12345 {{! Comment Block! }} 67890"
      input = {}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "12345  67890"
    end
  end
  describe "Variable Name Collision" do
    specify "Comments must never render, even if variable with same name exists." do
      template = "comments never show: >{{! comment }}<"
      input = {"! comment" => 1, "! comment " => 2, "!comment" => 3, "comment" => 4}
      result = compiler.compile(template, compat: true).call(input)
      _(result).must_equal "comments never show: ><"
    end
  end
end
