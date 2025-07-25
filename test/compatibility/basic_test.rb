# frozen_string_literal: true

require "test_helper"

# Based on spec/basic.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/basic.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'basic context' do
  it 'most basic' do
    expectTemplate('{{foo}}').withInput({ foo: 'foo' }).toCompileTo('foo');
  end

  it 'escaping' do
    expectTemplate('\\{{foo}}')
      .withInput({ foo: 'food' })
      .toCompileTo('{{foo}}');

    expectTemplate('content \\{{foo}}')
      .withInput({ foo: 'food' })
      .toCompileTo('content {{foo}}');

    expectTemplate('\\\\{{foo}}')
      .withInput({ foo: 'food' })
      .toCompileTo('\\food');

    expectTemplate('content \\\\{{foo}}')
      .withInput({ foo: 'food' })
      .toCompileTo('content \\food');

    expectTemplate('\\\\ {{foo}}')
      .withInput({ foo: 'food' })
      .toCompileTo('\\\\ food');
  end

  it 'compiling with a basic context' do
    expectTemplate('Goodbye\n{{cruel}}\n{{world}}!')
      .withInput({
        cruel: 'cruel',
        world: 'world',
      })
      .withMessage('It works if all the required keys are provided')
      .toCompileTo('Goodbye\ncruel\nworld!');
  end

  it 'compiling with a string context' do
    expectTemplate('{{.}}{{length}}').withInput('bye').toCompileTo('bye3');
  end

  it 'compiling with an undefined context' do
    undefined = nil
    expectTemplate('Goodbye\n{{cruel}}\n{{world.bar}}!')
      .withInput(undefined)
      .toCompileTo('Goodbye\n\n!');

    expectTemplate('{{#unless foo}}Goodbye{{../test}}{{test2}}{{/unless}}')
      .withInput(undefined)
      .toCompileTo('Goodbye');
  end

  it 'comments' do
    expectTemplate('{{! Goodbye}}Goodbye\n{{cruel}}\n{{world}}!')
      .withInput({
        cruel: 'cruel',
        world: 'world',
      })
      .withMessage('comments are ignored')
      .toCompileTo('Goodbye\ncruel\nworld!');

    expectTemplate('    {{~! comment ~}}      blah').toCompileTo('blah');

    expectTemplate('    {{~!-- long-comment --~}}      blah').toCompileTo(
      'blah'
    );

    expectTemplate('    {{! comment ~}}      blah').toCompileTo('    blah');

    expectTemplate('    {{!-- long-comment --~}}      blah').toCompileTo(
      '    blah'
    );

    expectTemplate('    {{~! comment}}      blah').toCompileTo('      blah');

    expectTemplate('    {{~!-- long-comment --}}      blah').toCompileTo(
      '      blah'
    );
  end

  it 'boolean' do
    string = '{{#goodbye}}GOODBYE {{/goodbye}}cruel {{world}}!';
    expectTemplate(string)
      .withInput({
        goodbye: true,
        world: 'world',
      })
      .withMessage('booleans show the contents when true')
      .toCompileTo('GOODBYE cruel world!');

    expectTemplate(string)
      .withInput({
        goodbye: false,
        world: 'world',
      })
      .withMessage('booleans do not show the contents when false')
      .toCompileTo('cruel world!');
  end

  it 'zeros' do
    expectTemplate('num1: {{num1}}, num2: {{num2}}')
      .withInput({
        num1: 42,
        num2: 0,
      })
      .toCompileTo('num1: 42, num2: 0');

    expectTemplate('num: {{.}}').withInput(0).toCompileTo('num: 0');

    expectTemplate('num: {{num1/num2}}')
      .withInput({ num1: { num2: 0 } })
      .toCompileTo('num: 0');
  end

  it 'false' do
    expectTemplate('val1: {{val1}}, val2: {{val2}}')
      .withInput({
        val1: false,
        val2: false,
      })
      .toCompileTo('val1: false, val2: false');

    expectTemplate('val: {{.}}').withInput(false).toCompileTo('val: false');

    expectTemplate('val: {{val1/val2}}')
      .withInput({ val1: { val2: false } })
      .toCompileTo('val: false');

    expectTemplate('val1: {{{val1}}}, val2: {{{val2}}}')
      .withInput({
        val1: false,
        val2: false,
      })
      .toCompileTo('val1: false, val2: false');

    expectTemplate('val: {{{val1/val2}}}')
      .withInput({ val1: { val2: false } })
      .toCompileTo('val: false');
  end

  it 'should handle undefined and null' do
    undefined = nil
    null = nil

    # rubocop:disable Lint/UnderscorePrefixedVariableName
    expectTemplate('{{awesome undefined null}}')
      .withInput({
        awesome: lambda { |_undefined, _null, options|
          return (
            (_undefined == undefined).to_s +
            ' ' +
            (_null == null).to_s +
            ' ' +
            options.class.to_s
          );
        },
      })
      .toCompileTo('true true Haparanda::HandlebarsProcessor::Options');
    # rubocop:enable Lint/UnderscorePrefixedVariableName

    expectTemplate('{{undefined}}')
      .withInput({
        undefined: lambda {
          return 'undefined!';
        },
      })
      .toCompileTo('undefined!');

    expectTemplate('{{null}}')
      .withInput({
        null: lambda {
          return 'null!';
        },
      })
      .toCompileTo('null!');
  end

  it 'newlines' do
    expectTemplate("Alan's\nTest").toCompileTo("Alan's\nTest");

    expectTemplate("Alan's\rTest").toCompileTo("Alan's\rTest");
  end

  it 'escaping text' do
    expectTemplate("Awesome's")
      .withMessage(
        "text is escaped so that it doesn't get caught on single quotes"
      )
      .toCompileTo("Awesome's");

    expectTemplate('Awesome\\')
      .withMessage("text is escaped so that the closing quote can't be ignored")
      .toCompileTo('Awesome\\');

    expectTemplate('Awesome\\\\ foo')
      .withMessage("text is escaped so that it doesn't mess up backslashes")
      .toCompileTo('Awesome\\\\ foo');

    expectTemplate('Awesome {{foo}}')
      .withInput({ foo: '\\' })
      .withMessage("text is escaped so that it doesn't mess up backslashes")
      .toCompileTo('Awesome \\');

    expectTemplate(" ' ' ")
      .withMessage('double quotes never produce invalid javascript')
      .toCompileTo(" ' ' ");
  end

  it 'escaping expressions' do
    expectTemplate('{{{awesome}}}')
      .withInput({ awesome: "&'\\<>" })
      .withMessage("expressions with 3 handlebars aren't escaped")
      .toCompileTo("&'\\<>");

    expectTemplate('{{&awesome}}')
      .withInput({ awesome: "&'\\<>" })
      .withMessage("expressions with {{& handlebars aren't escaped")
      .toCompileTo("&'\\<>");

    expectTemplate('{{awesome}}')
      .withInput({ awesome: '&"\'`\\<>' })
      .withMessage('by default expressions should be escaped')
      .toCompileTo('&amp;&quot;&#x27;&#x60;\\&lt;&gt;');

    expectTemplate('{{awesome}}')
      .withInput({ awesome: 'Escaped, <b> looks like: &lt;b&gt;' })
      .withMessage('escaping should properly handle amperstands')
      .toCompileTo('Escaped, &lt;b&gt; looks like: &amp;lt;b&amp;gt;');
  end

  it "functions returning safestrings shouldn't be escaped" do
    expectTemplate('{{awesome}}')
      .withInput({
        awesome: lambda {
          return Haparanda::HandlebarsProcessor::SafeString.new("&'\\<>");
        },
      })
      .withMessage("functions returning safestrings aren't escaped")
      .toCompileTo("&'\\<>");
  end

  it 'functions' do
    expectTemplate('{{awesome}}')
      .withInput({
        awesome: lambda {
          return 'Awesome';
        },
      })
      .withMessage('functions are called and render their output')
      .toCompileTo('Awesome');

    expectTemplate('{{awesome}}')
      .withInput({
        awesome: lambda {
          return this.more;
        },
        more: 'More awesome',
      })
      .withMessage('functions are bound to the context')
      .toCompileTo('More awesome');
  end

  it 'functions with context argument' do
    expectTemplate('{{awesome frank}}')
      .withInput({
        awesome: lambda { |context|
          return context;
        },
        frank: 'Frank',
      })
      .withMessage('functions are called with context arguments')
      .toCompileTo('Frank');
  end

  it 'pathed functions with context argument' do
    expectTemplate('{{bar.awesome frank}}')
      .withInput({
        bar: {
          awesome: lambda { |context|
            return context;
          },
        },
        frank: 'Frank',
      })
      .withMessage('functions are called with context arguments')
      .toCompileTo('Frank');
  end

  it 'depthed functions with context argument' do
    expectTemplate('{{#with frank}}{{../awesome .}}{{/with}}')
      .withInput({
        awesome: lambda { |context|
          return context;
        },
        frank: 'Frank',
      })
      .withMessage('functions are called with context arguments')
      .toCompileTo('Frank');
  end

  it 'block functions with context argument' do
    expectTemplate('{{#awesome 1}}inner {{.}}{{/awesome}}')
      .withInput({
        awesome: lambda { |context, options|
          return options.fn(context);
        },
      })
      .withMessage('block functions are called with context and options')
      .toCompileTo('inner 1');
  end

  it 'depthed block functions with context argument' do
    expectTemplate(
      '{{#with value}}{{#../awesome 1}}inner {{.}}{{/../awesome}}{{/with}}'
    )
      .withInput({
        value: true,
        awesome: lambda { |context, options|
          return options.fn(context);
        },
      })
      .withMessage('block functions are called with context and options')
      .toCompileTo('inner 1');
  end

  it 'block functions without context argument' do
    expectTemplate('{{#awesome}}inner{{/awesome}}')
      .withInput({
        awesome: lambda { |options|
          return options.fn(this);
        },
      })
      .withMessage('block functions are called with options')
      .toCompileTo('inner');
  end

  it 'pathed block functions without context argument' do
    expectTemplate('{{#foo.awesome}}inner{{/foo.awesome}}')
      .withInput({
        foo: {
          awesome: lambda {
            return this;
          },
        },
      })
      .withMessage('block functions are called with options')
      .toCompileTo('inner');
  end

  it 'depthed block functions without context argument' do
    expectTemplate(
      '{{#with value}}{{#../awesome}}inner{{/../awesome}}{{/with}}'
    )
      .withInput({
        value: true,
        awesome: lambda {
          return this;
        },
      })
      .withMessage('block functions are called with options')
      .toCompileTo('inner');
  end

  it 'paths with hyphens' do
    expectTemplate('{{foo-bar}}')
      .withInput({ 'foo-bar': 'baz' })
      .withMessage('Paths can contain hyphens (-)')
      .toCompileTo('baz');

    expectTemplate('{{foo.foo-bar}}')
      .withInput({ foo: { 'foo-bar': 'baz' } })
      .withMessage('Paths can contain hyphens (-)')
      .toCompileTo('baz');

    expectTemplate('{{foo/foo-bar}}')
      .withInput({ foo: { 'foo-bar': 'baz' } })
      .withMessage('Paths can contain hyphens (-)')
      .toCompileTo('baz');
  end

  it 'nested paths' do
    expectTemplate('Goodbye {{alan/expression}} world!')
      .withInput({ alan: { expression: 'beautiful' } })
      .withMessage('Nested paths access nested objects')
      .toCompileTo('Goodbye beautiful world!');
  end

  it 'nested paths with Map' do
    skip
    expectTemplate('Goodbye {{alan/expression}} world!')
      .withInput({ alan: Map.new([['expression', 'beautiful']]) })
      .withMessage('Nested paths access nested objects')
      .toCompileTo('Goodbye beautiful world!');
  end

  it 'nested paths with empty string value' do
    expectTemplate('Goodbye {{alan/expression}} world!')
      .withInput({ alan: { expression: '' } })
      .withMessage('Nested paths access nested objects with empty string')
      .toCompileTo('Goodbye  world!');
  end

  it 'literal paths' do
    expectTemplate('Goodbye {{[@alan]/expression}} world!')
      .withInput({ '@alan': { expression: 'beautiful' } })
      .withMessage('Literal paths can be used')
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{[foo bar]/expression}} world!')
      .withInput({ 'foo bar': { expression: 'beautiful' } })
      .withMessage('Literal paths can be used')
      .toCompileTo('Goodbye beautiful world!');
  end

  it 'literal references' do
    expectTemplate('Goodbye {{[foo bar]}} world!')
      .withInput({ 'foo bar': 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{"foo bar"}} world!')
      .withInput({ 'foo bar' => 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate("Goodbye {{'foo bar'}} world!")
      .withInput({ 'foo bar' => 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{"foo[bar"}} world!')
      .withInput({ 'foo[bar' => 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{"foo\'bar"}} world!')
      .withInput({ "foo'bar" => 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate("Goodbye {{'foo\"bar'}} world!")
      .withInput({ 'foo"bar' => 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');
  end

  it "that current context path ({{.}}) doesn't hit helpers" do
    null = nil
    expectTemplate('test: {{.}}')
      .withInput(null)
      .withHelpers({ helper: -> { 'awesome' } })
      .toCompileTo('test: ');
  end

  it 'complex but empty paths' do
    null = nil
    expectTemplate('{{person/name}}')
      .withInput({ person: { name: null } })
      .toCompileTo('');

    expectTemplate('{{person/name}}').withInput({ person: {} }).toCompileTo('');
  end

  it 'this keyword in paths' do
    expectTemplate('{{#goodbyes}}{{this}}{{/goodbyes}}')
      .withInput({ goodbyes: ['goodbye', 'Goodbye', 'GOODBYE'] })
      .withMessage('This keyword in paths evaluates to current context')
      .toCompileTo('goodbyeGoodbyeGOODBYE');

    expectTemplate('{{#hellos}}{{this/text}}{{/hellos}}')
      .withInput({
        hellos: [{ text: 'hello' }, { text: 'Hello' }, { text: 'HELLO' }],
      })
      .withMessage('This keyword evaluates in more complex paths')
      .toCompileTo('helloHelloHELLO');
  end

  it 'this keyword nested inside path' do
    expectTemplate('{{#hellos}}{{text/this/foo}}{{/hellos}}').toThrow(
      Racc::ParseError,
      'Invalid path: text/this - 1'
    );

    skip
    expectTemplate('{{[this]}}').withInput({ this: 'bar' }).toCompileTo('bar');

    expectTemplate('{{text/[this]}}')
      .withInput({ text: { this: 'bar' } })
      .toCompileTo('bar');
  end

  it 'this keyword in helpers' do
    helpers = {
      foo: lambda { |value|
        return 'bar ' + value;
      },
    };

    expectTemplate('{{#goodbyes}}{{foo this}}{{/goodbyes}}')
      .withInput({ goodbyes: ['goodbye', 'Goodbye', 'GOODBYE'] })
      .withHelpers(helpers)
      .withMessage('This keyword in paths evaluates to current context')
      .toCompileTo('bar goodbyebar Goodbyebar GOODBYE');

    expectTemplate('{{#hellos}}{{foo this/text}}{{/hellos}}')
      .withInput({
        hellos: [{ text: 'hello' }, { text: 'Hello' }, { text: 'HELLO' }],
      })
      .withHelpers(helpers)
      .withMessage('This keyword evaluates in more complex paths')
      .toCompileTo('bar hellobar Hellobar HELLO');
  end

  it 'this keyword nested inside helpers param' do
    skip
    expectTemplate('{{#hellos}}{{foo text/this/foo}}{{/hellos}}').toThrow(
      Error,
      'Invalid path: text/this - 1:17'
    );

    expectTemplate('{{foo [this]}}')
      .withInput({
        foo: lambda { |value|
          return value;
        },
        this: 'bar',
      })
      .toCompileTo('bar');

    expectTemplate('{{foo text/[this]}}')
      .withInput({
        foo: lambda { |value|
          return value;
        },
        text: { this: 'bar' },
      })
      .toCompileTo('bar');
  end

  it 'pass string literals' do
    expectTemplate('{{"foo"}}').toCompileTo('');

    expectTemplate('{{"foo"}}').withInput({ "foo" => 'bar' }).toCompileTo('bar');

    expectTemplate('{{#"foo"}}{{.}}{{/"foo"}}')
      .withInput({
        "foo" => ['bar', 'baz'],
      })
      .toCompileTo('barbaz');
  end

  it 'pass number literals' do
    expectTemplate('{{12}}').toCompileTo('');

    expectTemplate('{{12}}').withInput({ 12 => 'bar' }).toCompileTo('bar');

    expectTemplate('{{12.34}}').toCompileTo('');

    expectTemplate('{{12.34}}').withInput({ 12.34 => 'bar' }).toCompileTo('bar');

    expectTemplate('{{12.34 1}}')
      .withInput({
        12.34 => lambda { |arg|
          return 'bar' + arg.to_s;
        },
      })
      .toCompileTo('bar1');
  end

  it 'pass boolean literals' do
    expectTemplate('{{true}}').toCompileTo('');

    expectTemplate('{{true}}').withInput({ '': 'foo' }).toCompileTo('');

    expectTemplate('{{false}}').withInput({ false => 'foo' }).toCompileTo('foo');
  end

  it 'should handle literals in subexpression' do
    skip
    expectTemplate('{{foo (false)}}')
      .withInput({
        false => lambda {
          return 'bar';
        },
      })
      .withHelper('foo', lambda { |arg|
        return arg;
      })
      .toCompileTo('bar');
  end
end
