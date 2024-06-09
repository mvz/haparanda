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
    _, data, id = expr.shift(3)
    ids = [id]
    ids << expr.shift while expr.any?

    s(:print, "#{'@' if data}PATH:#{ids.join('/')}")
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
  # rubocop:disable Layout/LineLength
  it 'parses simple mustaches' do
    equals(astFor('{{123}}'), '{{ NUMBER{123} [] }}\n');
    equals(astFor('{{"foo"}}'), '{{ "foo" [] }}\n');
    equals(astFor('{{false}}'), '{{ BOOLEAN{false} [] }}\n');
    equals(astFor('{{true}}'), '{{ BOOLEAN{true} [] }}\n');
    equals(astFor('{{foo}}'), '{{ PATH:foo [] }}\n');
    equals(astFor('{{foo?}}'), '{{ PATH:foo? [] }}\n');
    equals(astFor('{{foo_}}'), '{{ PATH:foo_ [] }}\n');
    equals(astFor('{{foo-}}'), '{{ PATH:foo- [] }}\n');
    equals(astFor('{{foo:}}'), '{{ PATH:foo: [] }}\n');
  end

  it 'parses simple mustaches with data' do
    equals(astFor('{{@foo}}'), '{{ @PATH:foo [] }}\n');
  end

  it 'parses simple mustaches with data paths' do
    equals(astFor('{{@../foo}}'), '{{ @PATH:foo [] }}\n');
  end

  it 'parses mustaches with paths' do
    equals(astFor('{{foo/bar}}'), '{{ PATH:foo/bar [] }}\n');
  end

  it 'parses mustaches with this/foo' do
    equals(astFor('{{this/foo}}'), '{{ PATH:foo [] }}\n');
  end

  it 'parses mustaches with - in a path' do
    equals(astFor('{{foo-bar}}'), '{{ PATH:foo-bar [] }}\n');
  end

  it 'parses mustaches with escaped [] in a path' do
    equals(astFor('{{[foo[\\]]}}'), '{{ PATH:foo[] [] }}\n');
  end
  it 'parses escaped \\\\ in path' do
    skip
    equals(astFor('{{[foo\\\\]}}'), '{{ PATH:foo\\ [] }}\n');
  end

  it 'parses mustaches with parameters' do
    skip
    equals(astFor('{{foo bar}}'), '{{ PATH:foo [PATH:bar] }}\n');
  end

  it 'parses mustaches with string parameters' do
    skip
    equals(astFor('{{foo bar "baz" }}'), '{{ PATH:foo [PATH:bar, "baz"] }}\n');
  end

  it 'parses mustaches with NUMBER parameters' do
    skip
    equals(astFor('{{foo 1}}'), '{{ PATH:foo [NUMBER{1}] }}\n');
  end

  it 'parses mustaches with BOOLEAN parameters' do
    skip
    equals(astFor('{{foo true}}'), '{{ PATH:foo [BOOLEAN{true}] }}\n');
    equals(astFor('{{foo false}}'), '{{ PATH:foo [BOOLEAN{false}] }}\n');
  end

  it 'parses mustaches with undefined and null paths' do
    skip
    equals(astFor('{{undefined}}'), '{{ UNDEFINED [] }}\n');
    equals(astFor('{{null}}'), '{{ NULL [] }}\n');
  end
  it 'parses mustaches with undefined and null parameters' do
    skip
    equals(
      astFor('{{foo undefined null}}'),
      '{{ PATH:foo [UNDEFINED, NULL] }}\n'
    );
  end

  it 'parses mustaches with DATA parameters' do
    skip
    equals(astFor('{{foo @bar}}'), '{{ PATH:foo [@PATH:bar] }}\n');
  end

  it 'parses mustaches with hash arguments' do
    skip
    equals(astFor('{{foo bar=baz}}'), '{{ PATH:foo [] HASH{bar=PATH:baz} }}\n');
    equals(astFor('{{foo bar=1}}'), '{{ PATH:foo [] HASH{bar=NUMBER{1}} }}\n');
    equals(
      astFor('{{foo bar=true}}'),
      '{{ PATH:foo [] HASH{bar=BOOLEAN{true}} }}\n'
    );
    equals(
      astFor('{{foo bar=false}}'),
      '{{ PATH:foo [] HASH{bar=BOOLEAN{false}} }}\n'
    );
    equals(
      astFor('{{foo bar=@baz}}'),
      '{{ PATH:foo [] HASH{bar=@PATH:baz} }}\n'
    );

    equals(
      astFor('{{foo bar=baz bat=bam}}'),
      '{{ PATH:foo [] HASH{bar=PATH:baz, bat=PATH:bam} }}\n'
    );
    equals(
      astFor('{{foo bar=baz bat="bam"}}'),
      '{{ PATH:foo [] HASH{bar=PATH:baz, bat="bam"} }}\n'
    );

    equals(astFor("{{foo bat='bam'}}"), '{{ PATH:foo [] HASH{bat="bam"} }}\n');

    equals(
      astFor('{{foo omg bar=baz bat="bam"}}'),
      '{{ PATH:foo [PATH:omg] HASH{bar=PATH:baz, bat="bam"} }}\n'
    );
    equals(
      astFor('{{foo omg bar=baz bat="bam" baz=1}}'),
      '{{ PATH:foo [PATH:omg] HASH{bar=PATH:baz, bat="bam", baz=NUMBER{1}} }}\n'
    );
    equals(
      astFor('{{foo omg bar=baz bat="bam" baz=true}}'),
      '{{ PATH:foo [PATH:omg] HASH{bar=PATH:baz, bat="bam", baz=BOOLEAN{true}} }}\n'
    );
    equals(
      astFor('{{foo omg bar=baz bat="bam" baz=false}}'),
      '{{ PATH:foo [PATH:omg] HASH{bar=PATH:baz, bat="bam", baz=BOOLEAN{false}} }}\n'
    );
  end

  it 'parses contents followed by a mustache' do
    skip
    equals(
      astFor('foo bar {{baz}}'),
      "CONTENT[ 'foo bar ' ]\n{{ PATH:baz [] }}\n"
    );
  end

  it 'parses a partial' do
    skip
    equals(astFor('{{> foo }}'), '{{> PARTIAL:foo }}\n');
    equals(astFor('{{> "foo" }}'), '{{> PARTIAL:foo }}\n');
    equals(astFor('{{> 1 }}'), '{{> PARTIAL:1 }}\n');
  end

  it 'parses a partial with context' do
    skip
    equals(astFor('{{> foo bar}}'), '{{> PARTIAL:foo PATH:bar }}\n');
  end

  it 'parses a partial with hash' do
    skip
    equals(
      astFor('{{> foo bar=bat}}'),
      '{{> PARTIAL:foo HASH{bar=PATH:bat} }}\n'
    );
  end

  it 'parses a partial with context and hash' do
    skip
    equals(
      astFor('{{> foo bar bat=baz}}'),
      '{{> PARTIAL:foo PATH:bar HASH{bat=PATH:baz} }}\n'
    );
  end

  it 'parses a partial with a complex name' do
    skip
    equals(
      astFor('{{> shared/partial?.bar}}'),
      '{{> PARTIAL:shared/partial?.bar }}\n'
    );
  end

  it 'parsers partial blocks' do
    skip
    equals(
      astFor('{{#> foo}}bar{{/foo}}'),
      "{{> PARTIAL BLOCK:foo PROGRAM:\n  CONTENT[ 'bar' ]\n }}\n"
    );
  end
  it 'parsers partial blocks with arguments' do
    skip
    equals(
      astFor('{{#> foo context hash=value}}bar{{/foo}}'),
      "{{> PARTIAL BLOCK:foo PATH:context HASH{hash=PATH:value} PROGRAM:\n  CONTENT[ 'bar' ]\n }}\n"
    );
  end

  it 'parses a comment' do
    skip
    equals(
      astFor('{{! this is a comment }}'),
      "{{! ' this is a comment ' }}\n"
    );
  end

  it 'parses a multi-line comment' do
    skip
    equals(
      astFor('{{!\nthis is a multi-line comment\n}}'),
      "{{! '\nthis is a multi-line comment\n' }}\n"
    );
  end

  it 'parses an inverse section' do
    skip
    equals(
      astFor('{{#foo}} bar {{^}} baz {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n    CONTENT[ ' baz ' ]\n"
    );
  end

  it 'parses an inverse (else-style) section' do
    skip
    equals(
      astFor('{{#foo}} bar {{else}} baz {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n    CONTENT[ ' baz ' ]\n"
    );
  end

  it 'parses multiple inverse sections' do
    skip
    equals(
      astFor('{{#foo}} bar {{else if bar}}{{else}} baz {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n    BLOCK:\n      PATH:if [PATH:bar]\n      PROGRAM:\n      {{^}}\n        CONTENT[ ' baz ' ]\n"
    );
  end

  it 'parses empty blocks' do
    skip
    equals(astFor('{{#foo}}{{/foo}}'), 'BLOCK:\n  PATH:foo []\n  PROGRAM:\n');
  end

  it 'parses empty blocks with empty inverse section' do
    skip
    equals(
      astFor('{{#foo}}{{^}}{{/foo}}'),
      'BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n'
    );
  end

  it 'parses empty blocks with empty inverse (else-style) section' do
    skip
    equals(
      astFor('{{#foo}}{{else}}{{/foo}}'),
      'BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n'
    );
  end

  it 'parses non-empty blocks with empty inverse section' do
    skip
    equals(
      astFor('{{#foo}} bar {{^}}{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n"
    );
  end

  it 'parses non-empty blocks with empty inverse (else-style) section' do
    skip
    equals(
      astFor('{{#foo}} bar {{else}}{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n"
    );
  end

  it 'parses empty blocks with non-empty inverse section' do
    skip
    equals(
      astFor('{{#foo}}{{^}} bar {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n    CONTENT[ ' bar ' ]\n"
    );
  end

  it 'parses empty blocks with non-empty inverse (else-style) section' do
    skip
    equals(
      astFor('{{#foo}}{{else}} bar {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n    CONTENT[ ' bar ' ]\n"
    );
  end

  it 'parses a standalone inverse section' do
    skip
    equals(
      astFor('{{^foo}}bar{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  {{^}}\n    CONTENT[ 'bar' ]\n"
    );
  end

  it 'parses block with block params' do
    skip
    equals(
      astFor('{{#foo as |bar baz|}}content{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    BLOCK PARAMS: [ bar baz ]\n    CONTENT[ 'content' ]\n"
    );
  end

  it 'parses mustaches with sub-expressions as the callable' do
    skip
    equals(
      astFor('{{(my-helper foo)}}'),
      '{{ PATH:my-helper [PATH:foo] [] }}\n'
    );
  end

  it 'parses mustaches with sub-expressions as the callable (with args)' do
    skip
    equals(
      astFor('{{(my-helper foo) bar}}'),
      '{{ PATH:my-helper [PATH:foo] [PATH:bar] }}\n'
    );
  end

  it 'parses sub-expressions with a sub-expression as the callable' do
    skip
    equals(
      astFor('{{((my-helper foo))}}'),
      '{{ PATH:my-helper [PATH:foo] [] [] }}\n'
    );
  end

  it 'parses sub-expressions with a sub-expression as the callable (with args)' do
    skip
    equals(
      astFor('{{((my-helper foo) bar)}}'),
      '{{ PATH:my-helper [PATH:foo] [PATH:bar] [] }}\n'
    );
  end

  it 'parses arguments with a sub-expression as the callable (with args)' do
    skip
    equals(
      astFor('{{my-helper ((foo) bar) baz=((foo bar))}}'),
      '{{ PATH:my-helper [PATH:foo [] [PATH:bar]] HASH{baz=PATH:foo [PATH:bar] []} }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root' do
    skip
    equals(
      astFor('{{(my-helper foo).bar}}'),
      '{{ PATH:[PATH:my-helper [PATH:foo]]/bar [] }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root as a callable' do
    skip
    equals(
      astFor('{{((my-helper foo).bar baz)}}'),
      '{{ PATH:[PATH:my-helper [PATH:foo]]/bar [PATH:baz] [] }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root as an argument' do
    skip
    equals(
      astFor('{{(foo (my-helper bar).baz)}}'),
      '{{ PATH:foo [PATH:[PATH:my-helper [PATH:bar]]/baz] [] }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root as a named argument' do
    skip
    equals(
      astFor('{{(foo bar=(my-helper baz).qux)}}'),
      '{{ PATH:foo [] HASH{bar=PATH:[PATH:my-helper [PATH:baz]]/qux} [] }}\n'
    );
  end

  it 'parses inverse block with block params' do
    skip
    equals(
      astFor('{{^foo as |bar baz|}}content{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  {{^}}\n    BLOCK PARAMS: [ bar baz ]\n    CONTENT[ 'content' ]\n"
    );
  end
  it 'parses chained inverse block with block params' do
    skip
    equals(
      astFor('{{#foo}}{{else foo as |bar baz|}}content{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n    BLOCK:\n      PATH:foo []\n      PROGRAM:\n        BLOCK PARAMS: [ bar baz ]\n        CONTENT[ 'content' ]\n"
    );
  end
  # rubocop:enable Layout/LineLength
  # rubocop:enable Style/Semicolon
  # rubocop:enable Style/StringLiterals
end
