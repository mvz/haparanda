# frozen_string_literal: true

require "test_helper"

describe WhitespaceHandler do
  let(:parser) { HandlebarsParser.new }
  let(:handler) { WhitespaceHandler.new }

  it "strips whitespace around simple mustaches" do
    raw = parser.parse "  {{~foo~}} "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, ""),
                           s(:mustache,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil, true,
                             s(:strip, true, true)), # TODO: Drop strip info from result
                           s(:content, ""))
  end

  it "strips whitespace inside blocks" do
    raw = parser.parse " {{# foo~}} \nbar\n {{~/foo}} "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, " "),
                           s(:block,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil,
                             s(:program, nil, s(:statements, s(:content, "bar"))),
                             nil, s(:strip, false, true), s(:strip, true, false)),
                           s(:content, " "))
  end

  it "strips whitespace outside blocks" do
    raw = parser.parse " {{~# foo}} bar {{/foo~}} "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, ""),
                           s(:block,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil,
                             s(:program, nil, s(:statements, s(:content, " bar "))),
                             nil, s(:strip, true, false), s(:strip, false, true)),
                           s(:content, ""))
  end
end
