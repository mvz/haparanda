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

  it "does not strip whitespace around standalone mustaches" do
    raw = parser.parse "foo \n {{bar}}  \n baz"
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, "foo \n "),
                           s(:mustache,
                             s(:path, false, s(:id, "bar")),
                             s(:exprs), nil, true,
                             s(:strip, false, false)),
                           s(:content, "  \n baz"))
  end

  it "strips whitespace around standalone starting block delimiters" do
    raw = parser.parse "foo \n {{# foo}} \nbar{{/foo}} \n baz \n "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, "foo \n"),
                           s(:block,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil,
                             s(:program, nil, s(:statements, s(:content, "bar"))),
                             nil, s(:strip, false, false), s(:strip, false, false)),
                           s(:content, " \n baz \n "))
  end

  it "strips whitespace around standalone ending block delimiters" do
    raw = parser.parse "foo \n {{# foo}}bar \n {{/foo}} \n baz \n "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, "foo \n "),
                           s(:block,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil,
                             s(:program, nil, s(:statements, s(:content, "bar \n"))),
                             nil, s(:strip, false, false), s(:strip, false, false)),
                           s(:content, " baz \n "))
  end

  it "strips whitespace around standalone block end delimiter with inverse delimiter" do
    raw = parser.parse "foo \n {{# foo}}bar {{else}}qux\n {{/foo}} \n baz \n "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, "foo \n "),
                           s(:block,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil,
                             s(:program, nil, s(:statements, s(:content, "bar "))),
                             s(:inverse, nil,
                               s(:statements, s(:content, "qux\n")),
                               s(:strip, false, false), s(:strip, false, false)),
                             s(:strip, false, false), s(:strip, false, false)),
                           s(:content, " baz \n "))
  end

  it "strips whitespace around standalone inverse delimiter" do
    raw = parser.parse "foo \n {{# foo}}bar\n {{else}}\n  qux\n {{/foo}} baz \n "
    result = handler.process raw
    _(result).must_equal s(:statements,
                           s(:content, "foo \n "),
                           s(:block,
                             s(:path, false, s(:id, "foo")),
                             s(:exprs), nil,
                             s(:program, nil, s(:statements, s(:content, "bar\n"))),
                             s(:inverse, nil,
                               s(:statements, s(:content, "  qux\n ")),
                               s(:strip, false, false), s(:strip, false, false)),
                             s(:strip, false, false), s(:strip, false, false)),
                           s(:content, " baz \n "))
  end
end
