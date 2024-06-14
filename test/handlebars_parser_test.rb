# frozen_string_literal: true

require "test_helper"

describe HandlebarsParser do
  let(:parser) { HandlebarsParser.new }

  # Helper methods to make assertions most similar to original
  # handlebars-parser test assertions.
  def equals(act, exp)
    exp = exp.gsub('\n', "\n")
    _(act).must_equal exp
  end

  def astFor(str) # rubocop:disable Naming/MethodName
    str = str.gsub('\n', "\n")
    result = parser.parse str
    PrintingProcessor.new.print(result)
  end

  def shouldThrow(function, error, message = nil) # rubocop:disable Naming/MethodName
    exception = _(function).must_raise error
    _(exception.message).must_match message if message
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
    equals(astFor('{{[foo\\\\]}}'), '{{ PATH:foo\\ [] }}\n');
  end

  it 'parses mustaches with parameters' do
    equals(astFor('{{foo bar}}'), '{{ PATH:foo [PATH:bar] }}\n');
  end

  it 'parses mustaches with string parameters' do
    equals(astFor('{{foo bar "baz" }}'), '{{ PATH:foo [PATH:bar, "baz"] }}\n');
  end

  it 'parses mustaches with NUMBER parameters' do
    equals(astFor('{{foo 1}}'), '{{ PATH:foo [NUMBER{1}] }}\n');
  end

  it 'parses mustaches with BOOLEAN parameters' do
    equals(astFor('{{foo true}}'), '{{ PATH:foo [BOOLEAN{true}] }}\n');
    equals(astFor('{{foo false}}'), '{{ PATH:foo [BOOLEAN{false}] }}\n');
  end

  it 'parses mustaches with undefined and null paths' do
    equals(astFor('{{undefined}}'), '{{ UNDEFINED [] }}\n');
    equals(astFor('{{null}}'), '{{ NULL [] }}\n');
  end
  it 'parses mustaches with undefined and null parameters' do
    equals(
      astFor('{{foo undefined null}}'),
      '{{ PATH:foo [UNDEFINED, NULL] }}\n'
    );
  end

  it 'parses mustaches with DATA parameters' do
    equals(astFor('{{foo @bar}}'), '{{ PATH:foo [@PATH:bar] }}\n');
  end

  it 'parses mustaches with hash arguments' do
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
    equals(
      astFor('foo bar {{baz}}'),
      "CONTENT[ 'foo bar ' ]\n{{ PATH:baz [] }}\n"
    );
  end

  it 'parses a partial' do
    equals(astFor('{{> foo }}'), '{{> PARTIAL:foo }}\n');
    equals(astFor('{{> "foo" }}'), '{{> PARTIAL:foo }}\n');
    equals(astFor('{{> 1 }}'), '{{> PARTIAL:1 }}\n');
  end

  it 'parses a partial with context' do
    equals(astFor('{{> foo bar}}'), '{{> PARTIAL:foo PATH:bar }}\n');
  end

  it 'parses a partial with hash' do
    equals(
      astFor('{{> foo bar=bat}}'),
      '{{> PARTIAL:foo HASH{bar=PATH:bat} }}\n'
    );
  end

  it 'parses a partial with context and hash' do
    equals(
      astFor('{{> foo bar bat=baz}}'),
      '{{> PARTIAL:foo PATH:bar HASH{bat=PATH:baz} }}\n'
    );
  end

  it 'parses a partial with a complex name' do
    equals(
      astFor('{{> shared/partial?.bar}}'),
      '{{> PARTIAL:shared/partial?.bar }}\n'
    );
  end

  it 'parses partial blocks' do
    equals(
      astFor('{{#> foo}}bar{{/foo}}'),
      "{{> PARTIAL BLOCK:foo PROGRAM:\n  CONTENT[ 'bar' ]\n }}\n"
    );
  end

  it 'should handle partial block name mismatch' do
    shouldThrow(
      lambda {
        astFor('{{#> goodbyes}}{{/hellos}}');
      },
      ParseError,
      /goodbyes doesn't match hellos/
    );
  end

  it 'parsers partial blocks with arguments' do
    equals(
      astFor('{{#> foo context hash=value}}bar{{/foo}}'),
      "{{> PARTIAL BLOCK:foo PATH:context HASH{hash=PATH:value} PROGRAM:\n  CONTENT[ 'bar' ]\n }}\n"
    );
  end

  it 'parses a comment' do
    equals(
      astFor('{{! this is a comment }}'),
      "{{! ' this is a comment ' }}\n"
    );
  end

  it 'parses a multi-line comment' do
    equals(
      astFor('{{!\nthis is a multi-line comment\n}}'),
      "{{! '\nthis is a multi-line comment\n' }}\n"
    );
  end

  it 'parses an inverse section' do
    equals(
      astFor('{{#foo}} bar {{^}} baz {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n    CONTENT[ ' baz ' ]\n"
    );
  end

  it 'parses an inverse (else-style) section' do
    equals(
      astFor('{{#foo}} bar {{else}} baz {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n    CONTENT[ ' baz ' ]\n"
    );
  end

  it 'parses multiple inverse sections' do
    equals(
      astFor('{{#foo}} bar {{else if bar}}{{else}} baz {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n    BLOCK:\n      PATH:if [PATH:bar]\n      PROGRAM:\n      {{^}}\n        CONTENT[ ' baz ' ]\n"
    );
  end

  it 'parses empty blocks' do
    equals(astFor('{{#foo}}{{/foo}}'), 'BLOCK:\n  PATH:foo []\n  PROGRAM:\n');
  end

  it 'parses empty blocks with empty inverse section' do
    equals(
      astFor('{{#foo}}{{^}}{{/foo}}'),
      'BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n'
    );
  end

  it 'parses empty blocks with empty inverse (else-style) section' do
    equals(
      astFor('{{#foo}}{{else}}{{/foo}}'),
      'BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n'
    );
  end

  it 'parses non-empty blocks with empty inverse section' do
    equals(
      astFor('{{#foo}} bar {{^}}{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n"
    );
  end

  it 'parses non-empty blocks with empty inverse (else-style) section' do
    equals(
      astFor('{{#foo}} bar {{else}}{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    CONTENT[ ' bar ' ]\n  {{^}}\n"
    );
  end

  it 'parses empty blocks with non-empty inverse section' do
    equals(
      astFor('{{#foo}}{{^}} bar {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n    CONTENT[ ' bar ' ]\n"
    );
  end

  it 'parses empty blocks with non-empty inverse (else-style) section' do
    equals(
      astFor('{{#foo}}{{else}} bar {{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n    CONTENT[ ' bar ' ]\n"
    );
  end

  it 'parses a standalone inverse section' do
    equals(
      astFor('{{^foo}}bar{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  {{^}}\n    CONTENT[ 'bar' ]\n"
    );
  end

  it 'throws on old inverse section' do
    shouldThrow(lambda {
      astFor('{{else foo}}bar{{/foo}}');
    }, ParseError);
  end

  it 'parses block with block params' do
    equals(
      astFor('{{#foo as |bar baz|}}content{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n    BLOCK PARAMS: [ bar baz ]\n    CONTENT[ 'content' ]\n"
    );
  end

  it 'parses mustaches with sub-expressions as the callable' do
    equals(
      astFor('{{(my-helper foo)}}'),
      '{{ PATH:my-helper [PATH:foo] [] }}\n'
    );
  end

  it 'parses mustaches with sub-expressions as the callable (with args)' do
    equals(
      astFor('{{(my-helper foo) bar}}'),
      '{{ PATH:my-helper [PATH:foo] [PATH:bar] }}\n'
    );
  end

  it 'parses sub-expressions with a sub-expression as the callable' do
    equals(
      astFor('{{((my-helper foo))}}'),
      '{{ PATH:my-helper [PATH:foo] [] [] }}\n'
    );
  end

  it 'parses sub-expressions with a sub-expression as the callable (with args)' do
    equals(
      astFor('{{((my-helper foo) bar)}}'),
      '{{ PATH:my-helper [PATH:foo] [PATH:bar] [] }}\n'
    );
  end

  it 'parses arguments with a sub-expression as the callable (with args)' do
    equals(
      astFor('{{my-helper ((foo) bar) baz=((foo bar))}}'),
      '{{ PATH:my-helper [PATH:foo [] [PATH:bar]] HASH{baz=PATH:foo [PATH:bar] []} }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root' do
    equals(
      astFor('{{(my-helper foo).bar}}'),
      '{{ PATH:[PATH:my-helper [PATH:foo]]/bar [] }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root as a callable' do
    equals(
      astFor('{{((my-helper foo).bar baz)}}'),
      '{{ PATH:[PATH:my-helper [PATH:foo]]/bar [PATH:baz] [] }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root as an argument' do
    equals(
      astFor('{{(foo (my-helper bar).baz)}}'),
      '{{ PATH:foo [PATH:[PATH:my-helper [PATH:bar]]/baz] [] }}\n'
    );
  end

  it 'parses paths with sub-expressions as the root as a named argument' do
    equals(
      astFor('{{(foo bar=(my-helper baz).qux)}}'),
      '{{ PATH:foo [] HASH{bar=PATH:[PATH:my-helper [PATH:baz]]/qux} [] }}\n'
    );
  end

  it 'parses inverse block with block params' do
    equals(
      astFor('{{^foo as |bar baz|}}content{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  {{^}}\n    BLOCK PARAMS: [ bar baz ]\n    CONTENT[ 'content' ]\n"
    );
  end

  it 'parses chained inverse block with block params' do
    equals(
      astFor('{{#foo}}{{else foo as |bar baz|}}content{{/foo}}'),
      "BLOCK:\n  PATH:foo []\n  PROGRAM:\n  {{^}}\n    BLOCK:\n      PATH:foo []\n      PROGRAM:\n        BLOCK PARAMS: [ bar baz ]\n        CONTENT[ 'content' ]\n"
    );
  end

  it "raises if there's a Parse error" do
    shouldThrow(
      lambda {
        astFor('foo{{^}}bar');
      },
      ParseError,
      /Parse error on line 1/
    );
    shouldThrow(
      lambda {
        astFor('{{foo}');
      },
      ParseError,
      /Parse error on line 1/
    );
    shouldThrow(
      lambda {
        astFor('{{foo &}}');
      },
      ParseError,
      /Parse error on line 1/
    );
  end

  it 'should handle block name mismatch' do
    shouldThrow(
      lambda {
        astFor('{{#goodbyes}}{{/hellos}}');
      },
      ParseError,
      /goodbyes doesn't match hellos/
    );
  end

  it "raises if there's a Parse error with too many braces" do
    shouldThrow(
      lambda {
        astFor('{{{{goodbyes}}}} {{{{/hellos}}}}');
      },
      ParseError,
      # NOTE: Parsing already fails on quadruple braces so the closing name is never checked
      /Parse error/
      # /goodbyes doesn't match hellos/
    );
  end

  # rubocop:disable Style/RegexpLiteral
  it 'should handle invalid paths' do
    shouldThrow(
      lambda {
        astFor('{{foo/../bar}}');
      },
      ParseError,
      /Invalid path: foo\/\.\. - 1:2/
    );
    shouldThrow(
      lambda {
        astFor('{{foo/./bar}}');
      },
      ParseError,
      /Invalid path: foo\/\. - 1:2/
    );
    shouldThrow(
      lambda {
        astFor('{{foo/this/bar}}');
      },
      ParseError,
      /Invalid path: foo\/this - 1:2/
    );
  end
  # rubocop:enable Style/RegexpLiteral

  it 'knows how to report the correct line number in errors' do
    shouldThrow(
      lambda {
        astFor('hello\nmy\n{{foo}');
      },
      ParseError,
      /Parse error on line 3/
    );
    shouldThrow(
      lambda {
        astFor('hello\n\nmy\n\n{{foo}');
      },
      ParseError,
      /Parse error on line 5/
    );
  end

  it 'knows how to report the correct line number in errors when the first character is a newline' do
    shouldThrow(
      lambda {
        astFor('\n\nhello\n\nmy\n\n{{foo}');
      },
      ParseError,
      /Parse error on line 7/
    );
  end

  # rubocop:disable Layout/FirstHashElementIndentation
  describe 'externally compiled AST' do
    it 'can pass through an already-compiled AST' do
      skip
      equals(
        astFor({
          type: 'Program',
          body: [{ type: 'ContentStatement', value: 'Hello' }]
        }),
        "CONTENT[ 'Hello' ]\n"
      );
    end
  end
  # rubocop:enable Layout/FirstHashElementIndentation

  describe 'directives' do
    it 'should parse block directives' do
      skip
      equals(
        astFor('{{#* foo}}{{/foo}}'),
        'DIRECTIVE BLOCK:\n  PATH:foo []\n  PROGRAM:\n'
      );
    end
    it 'should parse directives' do
      skip
      equals(astFor('{{* foo}}'), '{{ DIRECTIVE PATH:foo [] }}\n');
    end
    it 'should fail if directives have inverse' do
      skip
      shouldThrow(
        lambda {
          astFor('{{#* foo}}{{^}}{{/foo}}');
        },
        Error,
        /Unexpected inverse/
      );
    end
  end

  # rubocop:disable Style/LineEndConcatenation
  # rubocop:disable Style/StringConcatenation
  # rubocop:disable Layout/FirstHashElementIndentation
  it 'GH1024 - should track program location properly' do
    skip
    let p = parse(
      '\n' +
        '  {{#if foo}}\n' +
        '    {{bar}}\n' +
        '       {{else}}    {{baz}}\n' +
        '\n' +
        '     {{/if}}\n' +
        '    '
    );

    # We really need a deep equals but for now this should be stable...
    equals(
      JSON.stringify(p.loc),
      JSON.stringify({
        start: { line: 1, column: 0 },
        end: { line: 7, column: 4 }
      })
    );
    equals(
      JSON.stringify(p.body[1].program.loc),
      JSON.stringify({
        start: { line: 2, column: 13 },
        end: { line: 4, column: 7 }
      })
    );
    equals(
      JSON.stringify(p.body[1].inverse.loc),
      JSON.stringify({
        start: { line: 4, column: 15 },
        end: { line: 6, column: 5 }
      })
    );
  end
  # rubocop:enable Layout/FirstHashElementIndentation
  # rubocop:enable Style/StringConcatenation
  # rubocop:enable Style/LineEndConcatenation

  # rubocop:enable Layout/LineLength
  # rubocop:enable Style/Semicolon
  # rubocop:enable Style/StringLiterals
end
