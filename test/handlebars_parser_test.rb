# frozen_string_literal: true

require "test_helper"
require "sexp_processor"

class PrintingProcessor < SexpProcessor
  def print(expr)
    result = process(expr)
    raise "Unexpected result #{result}" unless result.sexp_type == :print

    result.sexp_body[0]
  end

  def process_mustache(expr)
    _, val, = expr.shift(5)
    val = print(val)
    s(:print, "{{ #{val} [] }}\\n")
  end

  def process_number(expr)
    _, val = expr.shift(2)
    s(:print, "NUMBER{#{val}}")
  end

  def process_boolean(expr)
    _, val = expr.shift(2)
    s(:print, "BOOLEAN{#{val}}")
  end

  def process_string(expr)
    _, val = expr.shift(2)
    s(:print, val.inspect)
  end

  def process_path(expr)
    _, id = expr.shift(2)
    s(:print, "PATH:#{id}")
  end
end

describe HandlebarsParser do
  let(:parser) { HandlebarsParser.new }

  # Helper methods to make assertions most similar to original
  # handlebars-parser test assertions.
  def equals(act, exp)
    _(act).must_equal exp
  end

  def astFor(str) # rubocop:disable Naming/MethodName
    result = parser.parse str
    PrintingProcessor.new.print(result)
  end

  it "parses content" do
    result = parser.parse "Hello!"

    _(result).must_equal(s(:content, "Hello!"))
  end

  # rubocop:disable Style/StringLiterals
  # rubocop:disable Style/Semicolon
  it "parses simple mustaches" do
    equals(astFor('{{123}}'), '{{ NUMBER{123} [] }}\n');
    equals(astFor('{{"foo"}}'), '{{ "foo" [] }}\n');
    equals(astFor('{{false}}'), '{{ BOOLEAN{false} [] }}\n');
    equals(astFor('{{true}}'), '{{ BOOLEAN{true} [] }}\n');
    equals(astFor('{{foo}}'), '{{ PATH:foo [] }}\n');
  end
  # rubocop:enable Style/Semicolon
  # rubocop:enable Style/StringLiterals
end
