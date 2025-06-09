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

  describe "#register_helper" do
    it "allows registering using a string" do
      compiler.register_helper("foo") { "bar" }
      template = compiler.compile "{{foo}}"
      result = template.call({})
      _(result).must_equal "bar"
    end

    it "allows explicit context parameter for helper" do
      compiler.register_helper("foo") { |context, _options| context.foo }
      template = compiler.compile "{{foo}}"
      result = template.call({ foo: "bar" })
      _(result).must_equal "bar"
    end
  end
end
