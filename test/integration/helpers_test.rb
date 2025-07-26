# frozen_string_literal: true

require "test_helper"

describe "helpers" do
  let(:compiler) { Haparanda::Compiler.new }

  describe "the options parameter" do
    it "has its name attribute set for mustaches" do
      compiler.register_helper("foo") { |options| "#{options.name}bar" }
      result = compiler.compile("{{foo}}").call({})

      _(result).must_equal "foobar"
    end

    it "has its name attribute set for blocks" do
      compiler.register_helper("foo") do |options|
        "#{options.name}#{options.fn}#{options.name}"
      end
      result = compiler.compile("{{#foo}}bar{{/foo}}").call({})

      _(result).must_equal "foobarfoo"
    end
  end
end
