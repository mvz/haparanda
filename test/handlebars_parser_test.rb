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
    _, val, _, _, _ = expr.shift(5)
    val = print(val)
    s(:print, "{{ #{val} [] }}")
  end

  def process_number(expr)
    _, val = expr.shift(2)
    s(:print, "NUMBER{#{val}}")
  end
end

describe HandlebarsParser do
  let(:parser) { HandlebarsParser.new }

  def equals(act, exp)
    _(act).must_equal exp
  end

  def astFor(str)
    result = parser.parse str
    PrintingProcessor.new.print(result)
  end

  it "parses content" do
    result = parser.parse "Hello!"

    _(result).must_equal(s(:content, "Hello!"))
  end

  it "parses simple mustaches" do
    equals(astFor('{{123}}'), '{{ NUMBER{123} [] }}')
  end
end
