# frozen_string_literal: true

require "test_helper"

# Based on spec/basic.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.

describe 'basic context' do
  class HandlebarsProcessor < SexpProcessor
    class Input
      def initialize(data)
        @data = data
      end

      def [](key)
        case @data
        when Hash
          @data[key]
        else
          @data.send key
        end
      end

      def to_s
        @data.to_s
      end
    end

    def initialize(input)
      super()
      @input = Input.new(input)
    end

    def apply(expr)
      result = process(expr)
      result[1]
    end

    def process_mustache(expr)
      _, path, _params, _hash, = expr.shift(5)
      value = if path[2].nil?
                @input
              else
                key = path[2][1].to_sym
                @input[key]
              end
      s(:result, value.to_s)
    end

    def process_block(expr)
      _, name, params, hash, program, inverse_chain, = expr.shift(8)
      key = name[2][1].to_sym
      if @input[key]
        process(program)
      else
        s(:result, "")
      end
    end

    def process_statements(expr)
      expr.shift
      statements = shift_all(expr)

      statements.each_cons(2) do |prev, item|
        if prev.sexp_type == :content && item.sexp_type != :content
          strip = item.last
          if strip[1]
            prev[1] = prev[1].sub(/\s*$/, "")
          end
        end
        if prev.sexp_type != :content && item.sexp_type == :content
          strip = prev.last
          if strip[2]
            item[1] = item[1].sub(/^\s*/, "")
          end
        end
      end

      results = statements.map { process(_1)[1] }
      s(:result, "#{results.join}")
    end

    def process_program(expr)
      _, params, statements, = expr.shift(3)
      statements = process(statements)[1] if statements
      s(:result, "#{statements}")
    end

    def process_comment(expr)
      _, _comment, = expr.shift(3)
      s(:result, "")
    end

    def shift_all(expr)
      result = []
      result << expr.shift while expr.any?
      result
    end
  end

  def expectTemplate(template)
    TemplateTester.new(template, self)
  end

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
    skip
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
    skip
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
    skip
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
    skip
    expectTemplate('{{awesome undefined null}}')
      .withInput({
        awesome: lambda(_undefined, _null, options) {
          return (
            (_undefined === undefined) +
            ' ' +
            (_null === null) +
            ' ' +
            options.class
          );
        },
      })
      .toCompileTo('true true object');

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
    skip
    expectTemplate("Alan's\nTest").toCompileTo("Alan's\nTest");

    expectTemplate("Alan's\rTest").toCompileTo("Alan's\rTest");
  end

  it 'escaping text' do
    skip
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
    skip
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
    skip
    expectTemplate('{{awesome}}')
      .withInput({
        awesome: lambda {
          return new Handlebars.SafeString("&'\\<>");
        },
      })
      .withMessage("functions returning safestrings aren't escaped")
      .toCompileTo("&'\\<>");
  end

  it 'functions' do
    skip
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
    skip
    expectTemplate('{{awesome frank}}')
      .withInput({
        awesome: ->(context) {
          return context;
        },
        frank: 'Frank',
      })
      .withMessage('functions are called with context arguments')
      .toCompileTo('Frank');
  end

  it 'pathed functions with context argument' do
    skip
    expectTemplate('{{bar.awesome frank}}')
      .withInput({
        bar: {
          awesome: ->(context) {
            return context;
          },
        },
        frank: 'Frank',
      })
      .withMessage('functions are called with context arguments')
      .toCompileTo('Frank');
  end

  it 'depthed functions with context argument' do
    skip
    expectTemplate('{{#with frank}}{{../awesome .}}{{/with}}')
      .withInput({
        awesome: ->(context) {
          return context;
        },
        frank: 'Frank',
      })
      .withMessage('functions are called with context arguments')
      .toCompileTo('Frank');
  end

  it 'block functions with context argument' do
    skip
    expectTemplate('{{#awesome 1}}inner {{.}}{{/awesome}}')
      .withInput({
        awesome: ->(context, options) {
          return options.fn(context);
        },
      })
      .withMessage('block functions are called with context and options')
      .toCompileTo('inner 1');
  end

  it 'depthed block functions with context argument' do
    skip
    expectTemplate(
      '{{#with value}}{{#../awesome 1}}inner {{.}}{{/../awesome}}{{/with}}'
    )
      .withInput({
        value: true,
        awesome: ->(context, options) {
          return options.fn(context);
        },
      })
      .withMessage('block functions are called with context and options')
      .toCompileTo('inner 1');
  end

  it 'block functions without context argument' do
    skip
    expectTemplate('{{#awesome}}inner{{/awesome}}')
      .withInput({
        awesome: ->(options) {
          return options.fn(this);
        },
      })
      .withMessage('block functions are called with options')
      .toCompileTo('inner');
  end

  it 'pathed block functions without context argument' do
    skip
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
    skip
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
    skip
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
    skip
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
    skip
    expectTemplate('Goodbye {{alan/expression}} world!')
      .withInput({ alan: { expression: '' } })
      .withMessage('Nested paths access nested objects with empty string')
      .toCompileTo('Goodbye  world!');
  end

  it 'literal paths' do
    skip
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
    skip
    expectTemplate('Goodbye {{[foo bar]}} world!')
      .withInput({ 'foo bar': 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{"foo bar"}} world!')
      .withInput({ 'foo bar': 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate("Goodbye {{'foo bar'}} world!")
      .withInput({ 'foo bar': 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{"foo[bar"}} world!')
      .withInput({ 'foo[bar': 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate('Goodbye {{"foo\'bar"}} world!')
      .withInput({ "foo'bar": 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');

    expectTemplate("Goodbye {{'foo\"bar'}} world!")
      .withInput({ 'foo"bar': 'beautiful' })
      .toCompileTo('Goodbye beautiful world!');
  end

  it "that current context path ({{.}}) doesn't hit helpers" do
    skip
    expectTemplate('test: {{.}}')
      .withInput(null)
      .withHelpers({ helper: 'awesome' })
      .toCompileTo('test: ');
  end

  it 'complex but empty paths' do
    skip
    expectTemplate('{{person/name}}')
      .withInput({ person: { name: null } })
      .toCompileTo('');

    expectTemplate('{{person/name}}').withInput({ person: {} }).toCompileTo('');
  end

  it 'this keyword in paths' do
    skip
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
    skip
    expectTemplate('{{#hellos}}{{text/this/foo}}{{/hellos}}').toThrow(
      Error,
      'Invalid path: text/this - 1:13'
    );

    expectTemplate('{{[this]}}').withInput({ this: 'bar' }).toCompileTo('bar');

    expectTemplate('{{text/[this]}}')
      .withInput({ text: { this: 'bar' } })
      .toCompileTo('bar');
  end

  it 'this keyword in helpers' do
    skip
    var helpers = {
      foo: ->(value) {
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
        foo: ->(value) {
          return value;
        },
        this: 'bar',
      })
      .toCompileTo('bar');

    expectTemplate('{{foo text/[this]}}')
      .withInput({
        foo: ->(value) {
          return value;
        },
        text: { this: 'bar' },
      })
      .toCompileTo('bar');
  end

  it 'pass string literals' do
    skip
    expectTemplate('{{"foo"}}').toCompileTo('');

    expectTemplate('{{"foo"}}').withInput({ foo: 'bar' }).toCompileTo('bar');

    expectTemplate('{{#"foo"}}{{.}}{{/"foo"}}')
      .withInput({
        foo: ['bar', 'baz'],
      })
      .toCompileTo('barbaz');
  end

  it 'pass number literals' do
    skip
    expectTemplate('{{12}}').toCompileTo('');

    expectTemplate('{{12}}').withInput({ 12 => 'bar' }).toCompileTo('bar');

    expectTemplate('{{12.34}}').toCompileTo('');

    expectTemplate('{{12.34}}').withInput({ 12.34 => 'bar' }).toCompileTo('bar');

    expectTemplate('{{12.34 1}}')
      .withInput({
        12.34 => ->(arg) {
          return 'bar' + arg;
        },
      })
      .toCompileTo('bar1');
  end

  it 'pass boolean literals' do
    skip
    expectTemplate('{{true}}').toCompileTo('');

    expectTemplate('{{true}}').withInput({ '': 'foo' }).toCompileTo('');

    expectTemplate('{{false}}').withInput({ false: 'foo' }).toCompileTo('foo');
  end

  it 'should handle literals in subexpression' do
    skip
    expectTemplate('{{foo (false)}}')
      .withInput({
        false: lambda {
          return 'bar';
        },
      })
      .withHelper('foo', ->(arg) {
        return arg;
      })
      .toCompileTo('bar');
  end
end
