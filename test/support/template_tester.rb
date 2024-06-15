# frozen_string_literal: true

require "handlebars_parser"

class TemplateTester
  def initialize(str, spec)
    @template = HandlebarsParser.new.parse(str)
    @spec = spec
    @input = {}
  end

  def withInput(input)
    @input = input
    self
  end

  def withMessage(message)
    @message = message
    self
  end

  def toCompileTo(expected)
    processor = HandlebarsProcessor.new(@input)
    actual = processor.apply(@template)
    @spec._(actual).must_equal expected, @message
  end
end
