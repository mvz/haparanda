# frozen_string_literal: true

require "test_helper"

describe HandlebarsParser do
  let(:parser) { HandlebarsParser.new }

  it "parses simple content" do
    result = parser.parse "Hello!"

    _(result).must_equal s(:root, s(:statements, s(:content, "Hello!")))
  end

  it "parses blocks with simple inverted sections" do
    result = parser.parse "{{#if foo}}foo{{else}}bar{{/if}}"
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:block,
                               s(:path, false, s(:id, "if")),
                               s(:exprs, s(:path, false, s(:id, "foo"))),
                               nil,
                               s(:program, nil, s(:statements, s(:content, "foo"))),
                               s(:inverse, nil,
                                 s(:statements, s(:content, "bar")),
                                 s(:strip, false, false), nil),
                               s(:strip, false, false), s(:strip, false, false))))
  end

  it "parses blocks with simple chained inverted section" do
    result = parser.parse "{{#if foo}}foo{{else if bar}}bar{{/if}}"
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:block,
                               s(:path, false, s(:id, "if")),
                               s(:exprs, s(:path, false, s(:id, "foo"))),
                               nil,
                               s(:program, nil, s(:statements, s(:content, "foo"))),
                               s(:inverse, nil,
                                 s(:block,
                                   s(:path, false, s(:id, "if")),
                                   s(:exprs, s(:path, false, s(:id, "bar"))),
                                   nil,
                                   s(:program, nil, s(:statements, s(:content, "bar"))),
                                   nil,
                                   s(:strip, false, false), nil),
                                 nil, nil),
                               s(:strip, false, false), s(:strip, false, false))))
  end

  it "parses blocks with complex chained inverted section" do
    result = parser.parse "{{#if foo}}foo{{else if bar}}bar{{else}}baz{{/if}}"
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:block,
                               s(:path, false, s(:id, "if")),
                               s(:exprs, s(:path, false, s(:id, "foo"))),
                               nil,
                               s(:program, nil, s(:statements, s(:content, "foo"))),
                               s(:inverse, nil,
                                 s(:block,
                                   s(:path, false, s(:id, "if")),
                                   s(:exprs, s(:path, false, s(:id, "bar"))),
                                   nil,
                                   s(:program, nil, s(:statements, s(:content, "bar"))),
                                   s(:inverse, nil,
                                     s(:statements, s(:content, "baz")),
                                     s(:strip, false, false), nil),
                                   s(:strip, false, false), nil),
                                 nil, nil),
                               s(:strip, false, false), s(:strip, false, false))))
  end
end
