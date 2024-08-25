# frozen_string_literal: true

require "test_helper"

# Based on spec/data.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.

describe 'data' do
  it 'passing in data to a compiled function that expects data - works with helpers' do
    expectTemplate('{{hello}}')
      .withCompileOptions({ data: true })
      .withHelper('hello', lambda { |options|
        return options.data.adjective + ' ' + this.noun;
      })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withInput({ noun: 'cat' })
      .withMessage('Data output by helper')
      .toCompileTo('happy cat');
  end

  it 'data can be looked up via @foo' do
    expectTemplate('{{@hello}}')
      .withRuntimeOptions({ data: { hello: 'hello' } })
      .withMessage('@foo retrieves template data')
      .toCompileTo('hello');
  end

  it 'deep @foo triggers automatic top-level data' do
    skip
    var helpers = Handlebars.createFrame(handlebarsEnv.helpers);

    helpers.let = lambda { |options|
      var frame = Handlebars.createFrame(options.data);

      options.hash.each_key do |prop|
        if options.hash.key? prop
          frame[prop] = options.hash[prop];
        end
      end
      return options.fn(this, { data: frame });
    };

    expectTemplate(
      '{{#let world="world"}}{{#if foo}}{{#if foo}}Hello {{@world}}{{/if}}{{/if}}{{/let}}'
    )
      .withInput({ foo: true })
      .withHelpers(helpers)
      .withMessage('Automatic data was triggered')
      .toCompileTo('Hello world');
  end

  it 'parameter data can be looked up via @foo' do
    expectTemplate('{{hello @world}}')
      .withRuntimeOptions({ data: { world: 'world' } })
      .withHelper('hello', lambda { |noun|
        return 'Hello ' + noun;
      })
      .withMessage('@foo as a parameter retrieves template data')
      .toCompileTo('Hello world');
  end

  it 'hash values can be looked up via @foo' do
    expectTemplate('{{hello noun=@world}}')
      .withRuntimeOptions({ data: { world: 'world' } })
      .withHelper('hello', lambda { |options|
        return 'Hello ' + options.hash[:noun];
      })
      .withMessage('@foo as a parameter retrieves template data')
      .toCompileTo('Hello world');
  end

  it 'nested parameter data can be looked up via @foo.bar' do
    expectTemplate('{{hello @world.bar}}')
      .withRuntimeOptions({ data: { world: { bar: 'world' } } })
      .withHelper('hello', lambda { |noun|
        return 'Hello ' + noun;
      })
      .withMessage('@foo as a parameter retrieves template data')
      .toCompileTo('Hello world');
  end

  it 'nested parameter data does not fail with @world.bar' do
    expectTemplate('{{hello @world.bar}}')
      .withRuntimeOptions({ data: { foo: { bar: 'world' } } })
      .withHelper('hello', lambda { |noun|
        return 'Hello ' + noun.to_s;
      })
      .withMessage('@foo as a parameter retrieves template data')
      .toCompileTo('Hello ');
  end

  it 'parameter data throws when using complex scope references' do
    expectTemplate(
      '{{#goodbyes}}{{text}} cruel {{@foo/../name}}! {{/goodbyes}}'
    ).toThrow(Racc::ParseError);
  end

  it 'data can be functions' do
    expectTemplate('{{@hello}}')
      .withRuntimeOptions({
        data: {
          hello: lambda {
            return 'hello';
          },
        },
      })
      .toCompileTo('hello');
  end

  it 'data can be functions with params' do
    expectTemplate('{{@hello "hello"}}')
      .withRuntimeOptions({
        data: {
          hello: lambda { |arg|
            return arg;
          },
        },
      })
      .toCompileTo('hello');
  end

  it 'data is inherited downstream' do
    skip
    expectTemplate(
      '{{#let foo=1 bar=2}}{{#let foo=bar.baz}}{{@bar}}{{@foo}}{{/let}}{{@foo}}{{/let}}'
    )
      .withInput({ bar: { baz: 'hello world' } })
      .withCompileOptions({ data: true })
      .withHelper('let', lambda { |options|
        var frame = Handlebars.createFrame(options.data);
        options.hash.each_key do |prop|
          if options.hash.key? prop
            frame[prop] = options.hash[prop];
          end
        end
        return options.fn(this, { data: frame });
      })
      .withRuntimeOptions({ data: {} })
      .withMessage('data variables are inherited downstream')
      .toCompileTo('2hello world1');
  end

  it 'passing in data to a compiled function that expects data - works with helpers in partials' do
    skip
    expectTemplate('{{>myPartial}}')
      .withCompileOptions({ data: true })
      .withPartial('myPartial', '{{hello}}')
      .withHelper('hello', lambda { |options|
        return options.data.adjective + ' ' + this.noun;
      })
      .withInput({ noun: 'cat' })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withMessage('Data output by helper inside partial')
      .toCompileTo('happy cat');
  end

  it 'passing in data to a compiled function that expects data - works with helpers and parameters' do
    expectTemplate('{{hello world}}')
      .withCompileOptions({ data: true })
      .withHelper('hello', lambda { |noun, options|
        return options.data.adjective + ' ' + noun + (this.exclaim ? '!' : '');
      })
      .withInput({ exclaim: true, world: 'world' })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withMessage('Data output by helper')
      .toCompileTo('happy world!');
  end

  it 'passing in data to a compiled function that expects data - works with block helpers' do
    expectTemplate('{{#hello}}{{world}}{{/hello}}')
      .withCompileOptions({
        data: true,
      })
      .withHelper('hello', lambda { |options|
        return options.fn(this);
      })
      .withHelper('world', lambda { |options|
        return options.data.adjective + ' world' + (this.exclaim ? '!' : '');
      })
      .withInput({ exclaim: true })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withMessage('Data output by helper')
      .toCompileTo('happy world!');
  end

  it 'passing in data to a compiled function that expects data - works with block helpers that use ..' do
    expectTemplate('{{#hello}}{{world ../zomg}}{{/hello}}')
      .withCompileOptions({ data: true })
      .withHelper('hello', lambda { |options|
        return options.fn({ exclaim: '?' });
      })
      .withHelper('world', lambda { |thing, options|
        return options.data.adjective + ' ' + thing + (this.exclaim || '');
      })
      .withInput({ exclaim: true, zomg: 'world' })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withMessage('Data output by helper')
      .toCompileTo('happy world?');
  end

  it 'passing in data to a compiled function that expects data - data is passed to with block helpers where children use ..' do
    expectTemplate('{{#hello}}{{world ../zomg}}{{/hello}}')
      .withCompileOptions({ data: true })
      .withHelper('hello', lambda { |options|
        return options.data.accessData + ' ' + options.fn({ exclaim: '?' });
      })
      .withHelper('world', lambda { |thing, options|
        return options.data.adjective + ' ' + thing + (this.exclaim || '');
      })
      .withInput({ exclaim: true, zomg: 'world' })
      .withRuntimeOptions({ data: { adjective: 'happy', accessData: '#win' } })
      .withMessage('Data output by helper')
      .toCompileTo('#win happy world?');
  end

  it 'you can override inherited data when invoking a helper' do
    skip
    expectTemplate('{{#hello}}{{world zomg}}{{/hello}}')
      .withCompileOptions({ data: true })
      .withHelper('hello', lambda { |options|
        return options.fn(
          { exclaim: '?', zomg: 'world' },
          { data: { adjective: 'sad' } }
        );
      })
      .withHelper('world', lambda { |thing, options|
        return options.data.adjective + ' ' + thing + (this.exclaim || '');
      })
      .withInput({ exclaim: true, zomg: 'planet' })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withMessage('Overridden data output by helper')
      .toCompileTo('sad world?');
  end

  it 'you can override inherited data when invoking a helper with depth' do
    skip
    expectTemplate('{{#hello}}{{world ../zomg}}{{/hello}}')
      .withCompileOptions({ data: true })
      .withHelper('hello', lambda { |options|
        return options.fn({ exclaim: '?' }, { data: { adjective: 'sad' } });
      })
      .withHelper('world', lambda { |thing, options|
        return options.data.adjective + ' ' + thing + (this.exclaim || '');
      })
      .withInput({ exclaim: true, zomg: 'world' })
      .withRuntimeOptions({ data: { adjective: 'happy' } })
      .withMessage('Overridden data output by helper')
      .toCompileTo('sad world?');
  end

  describe '@root' do
    it 'the root context can be looked up via @root' do
      skip
      expectTemplate('{{@root.foo}}')
        .withInput({ foo: 'hello' })
        .withRuntimeOptions({ data: {} })
        .toCompileTo('hello');

      expectTemplate('{{@root.foo}}')
        .withInput({ foo: 'hello' })
        .toCompileTo('hello');
    end

    it 'passed root values take priority' do
      skip
      expectTemplate('{{@root.foo}}')
        .withInput({ foo: 'should not be used' })
        .withRuntimeOptions({ data: { root: { foo: 'hello' } } })
        .toCompileTo('hello');
    end
  end

  describe 'nesting' do
    it 'the root context can be looked up via @root' do
      skip
      expectTemplate(
        '{{#helper}}{{#helper}}{{@./depth}} {{@../depth}} {{@../../depth}}{{/helper}}{{/helper}}'
      )
        .withInput({ foo: 'hello' })
        .withHelper('helper', lambda { |options|
          var frame = Handlebars.createFrame(options.data);
          frame.depth = options.data.depth + 1;
          return options.fn(this, { data: frame });
        })
        .withRuntimeOptions({
          data: {
            depth: 0,
          },
        })
        .toCompileTo('2 1 0');
    end
  end
end
