# frozen_string_literal: true

require "test_helper"

describe "basic operations" do
  let(:compiler) { Haparanda::Compiler.new }

  describe "value lookup" do
    it "allows 'this' as a regular path component if marked as a literal" do
      result = compiler.compile("{{[this]}}")
                       .call({ this: "bar" })

      _(result).must_equal "bar"
    end

    it "allows '.' as a regular path component if marked as a literal" do
      result = compiler.compile("{{[.]}}")
                       .call({ ".": "bar" })

      _(result).must_equal "bar"
    end

    it "allows '..' as a regular path component if marked as a literal" do
      result = compiler.compile("{{[..]}}")
                       .call({ "..": "bar" })

      _(result).must_equal "bar"
    end

    it "allows 'this' as a regular nested path component if marked as a literal" do
      result = compiler.compile("{{foo.[this]}}")
                       .call({ foo: { this: "bar" } })

      _(result).must_equal "bar"
    end

    it "allows '.' as a regular nested path component if marked as a literal" do
      result = compiler.compile("{{foo.[.]}}")
                       .call({ foo: { ".": "bar" } })

      _(result).must_equal "bar"
    end

    it "allows '..' as a regular nested path component if marked as a literal" do
      result = compiler.compile("{{foo.[..]}}")
                       .call({ foo: { "..": "bar" } })

      _(result).must_equal "bar"
    end
  end
end
