# frozen_string_literal: true

require "test_helper"

describe Haparanda::Template do
  let(:compiler) { Haparanda::Compiler.new }

  describe "#call" do
    it "returns the result of the processed template" do
      template = compiler.compile "Hello, {{who}}!"
      result = template.call({ who: "World" })

      _(result).must_equal "Hello, World!"
    end
  end
end
