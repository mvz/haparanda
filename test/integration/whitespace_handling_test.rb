# frozen_string_literal: true

require "test_helper"

describe "whitespace handling" do
  let(:compiler) { Haparanda::Compiler.new }

  describe "around partial blocks" do
    it "strips whitespace on the outside and inside" do
      result = compiler.compile("\n{{~#> dude ~}} success {{~/dude ~}}\n").call({})
      _(result).must_equal("success")
    end
    it "strips whitespace on the outside" do
      result = compiler.compile("\n{{~#> dude}} success {{/dude ~}}\n").call({})
      _(result).must_equal(" success ")
    end
    it "keeps whitespace if not marked as to be stripped" do
      result = compiler.compile("\n{{#> dude}} success {{/dude}}\n").call({})
      _(result).must_equal("\n success \n")
    end
    it "strips whitespace on the inside" do
      result = compiler.compile("\n{{#> dude ~}} success {{~/dude}}\n").call({})
      _(result).must_equal("\nsuccess\n")
    end
    it "strips whitespace around the end tag" do
      result = compiler.compile("\n{{#> dude}} success {{~/dude ~}}\n").call({})
      _(result).must_equal("\n success")
    end
  end

  describe "around inline partials" do
    it "strips whitespace on the outside and inside" do
      result = compiler.compile(
        "\n{{~#*inline \"myPartial\" ~}} success {{~/inline ~}}\n{{> myPartial}}"
      ).call({})
      _(result).must_equal("success")
    end
    it "strips whitespace on the outside" do
      result = compiler.compile(
        "\n{{~#*inline \"myPartial\"}} success {{/inline ~}}\n{{> myPartial}}"
      ).call({})
      _(result).must_equal(" success ")
    end
    it "keeps whitespace if not marked as to be stripped" do
      result = compiler.compile(
        "\n{{#*inline \"myPartial\" ~}} success {{~/inline}}\n{{> myPartial}}"
      ).call({})
      _(result).must_equal("\n\nsuccess")
    end
    it "strips whitespace on the inside" do
      result = compiler.compile(
        "\n{{#*inline \"myPartial\"}} success {{/inline}}\n{{> myPartial}}"
      ).call({})
      _(result).must_equal("\n\n success ")
    end
    it "strips whitespace around the end tag" do
      result = compiler.compile(
        "\n{{#*inline \"myPartial\"}} success {{~/inline ~}}\n{{> myPartial}}"
      ).call({})
      _(result).must_equal("\n success")
    end
  end
end
