# frozen_string_literal: true

require "test_helper"

describe Haparanda::Parser do
  let(:parser) { Haparanda::Parser.new }

  it "strips whitespace around simple mustaches" do
    result = parser.parse "  {{~foo~}} "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, ""),
                             s(:mustache,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil, true,
                               s(:strip, true, true)), # TODO: Drop strip info from result
                             s(:content, "")))
  end

  it "strips whitespace inside blocks" do
    result = parser.parse " {{# foo~}} \nbar\n {{~/foo}} "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, " "),
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, "bar"))),
                               nil, s(:strip, false, true), s(:strip, true, false)),
                             s(:content, " ")))
  end

  it "strips whitespace outside blocks" do
    result = parser.parse " {{~# foo}} bar {{/foo~}} "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, ""),
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, " bar "))),
                               nil, s(:strip, true, false), s(:strip, false, true)),
                             s(:content, "")))
  end

  it "does not strip whitespace around standalone mustaches" do
    result = parser.parse "foo \n {{bar}}  \n baz"
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, "foo \n "),
                             s(:mustache,
                               s(:path, false, s(:id, "bar")),
                               s(:exprs), nil, true,
                               s(:strip, false, false)),
                             s(:content, "  \n baz")))
  end

  it "strips whitespace around standalone starting block delimiters" do
    result = parser.parse "foo \n {{# foo}} \nbar{{/foo}} \n baz \n "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, "foo \n"),
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, "bar"))),
                               nil, s(:strip, false, false), s(:strip, false, false)),
                             s(:content, " \n baz \n ")))
  end

  it "strips whitespace around standalone ending block delimiters" do
    result = parser.parse "foo \n {{# foo}}bar \n {{/foo}} \n baz \n "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, "foo \n "),
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, "bar \n"))),
                               nil, s(:strip, false, false), s(:strip, false, false)),
                             s(:content, " baz \n ")))
  end

  it "strips whitespace around standalone block end delimiter with inverse delimiter" do
    result = parser.parse "foo \n {{# foo}}bar {{else}}qux\n {{/foo}} \n baz \n "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, "foo \n "),
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, "bar "))),
                               s(:inverse, nil,
                                 s(:statements, s(:content, "qux\n")),
                                 s(:strip, false, false), s(:strip, false, false)),
                               s(:strip, false, false), s(:strip, false, false)),
                             s(:content, " baz \n ")))
  end

  it "strips whitespace around standalone inverse delimiter" do
    result = parser.parse "foo \n {{# foo}}bar\n {{else}}\n  qux\n {{/foo}} baz \n "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:content, "foo \n "),
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, "bar\n"))),
                               s(:inverse, nil,
                                 s(:statements, s(:content, "  qux\n ")),
                                 s(:strip, false, false), s(:strip, false, false)),
                               s(:strip, false, false), s(:strip, false, false)),
                             s(:content, " baz \n ")))
  end

  it "strips whitespace after standalone template-initial starting block delimiter" do
    result = parser.parse "{{# foo}} \nbar{{/foo}} \n baz \n "
    _(result).must_equal s(:root,
                           s(:statements,
                             s(:block,
                               s(:path, false, s(:id, "foo")),
                               s(:exprs), nil,
                               s(:program, nil, s(:statements, s(:content, "bar"))),
                               nil, s(:strip, false, false), s(:strip, false, false)),
                             s(:content, " \n baz \n ")))
  end
end
