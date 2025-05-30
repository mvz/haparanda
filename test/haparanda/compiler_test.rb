# frozen_string_literal: true

require "test_helper"

describe Haparanda::Compiler do
  let(:compiler) { Haparanda::Compiler.new }

  describe "#compile" do
    it "returns a Haparanda::Template object" do
      result = compiler.compile "foo"
      _(result).must_be_instance_of Haparanda::Template
    end
  end
end
