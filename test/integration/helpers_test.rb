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

  describe "default missing block helper handling" do
    it "emits no output for missing values by default" do
      result = compiler.compile("{{#foo}}{{/foo}}").call({})
      _(result).must_equal ""
    end

    it "emits no output for missing helpers by default" do
      template = compiler.compile("{{#foo 1}}{{/foo}}")
      _(-> { template.call({}) }).must_raise RuntimeError, "Missing helper: \"foo\""
    end
  end

  describe "custom blockHelperMissing" do
    before do
      compiler.register_helper("blockHelperMissing") do |*, options|
        "block helper missing: #{options.name}"
      end
      compiler.register_helper("helperMissing") do |*, options|
        "helper missing: #{options.name}"
      end
    end

    it "is called for missing values in ambiguous block calls" do
      result = compiler.compile("{{#helper}}{{/helper}}").call({})
      _(result).must_equal "block helper missing: helper"
    end

    it "is called for non-missing values in ambiguous block calls" do
      result = compiler.compile("{{#foo}}{{/foo}}").call({ foo: "baz" })
      _(result).must_equal "block helper missing: foo"
    end

    it "is not called for missing helper block calls with params" do
      result = compiler.compile("{{#helper 1}}{{/helper}}").call({})
      _(result).must_equal "helper missing: helper"
    end
  end
end
