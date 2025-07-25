# frozen_string_literal: true

require "test_helper"

# Based on spec/blocks.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/blocks.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'blocks' do
  it 'array' do
    string = '{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!';

    expectTemplate(string)
      .withInput({
        goodbyes: [
          { text: 'goodbye' },
          { text: 'Goodbye' },
          { text: 'GOODBYE' },
        ],
        world: 'world',
      })
      .withMessage('Arrays iterate over the contents when not empty')
      .toCompileTo('goodbye! Goodbye! GOODBYE! cruel world!');

    expectTemplate(string)
      .withInput({
        goodbyes: [],
        world: 'world',
      })
      .withMessage('Arrays ignore the contents when empty')
      .toCompileTo('cruel world!');
  end

  it 'array without data' do
    expectTemplate(
      '{{#goodbyes}}{{text}}{{/goodbyes}} {{#goodbyes}}{{text}}{{/goodbyes}}'
    )
      .withInput({
        goodbyes: [
          { text: 'goodbye' },
          { text: 'Goodbye' },
          { text: 'GOODBYE' },
        ],
        world: 'world',
      })
      .withCompileOptions({ compat: false })
      .toCompileTo('goodbyeGoodbyeGOODBYE goodbyeGoodbyeGOODBYE');
  end

  it 'array with @index' do
    expectTemplate(
      '{{#goodbyes}}{{@index}}. {{text}}! {{/goodbyes}}cruel {{world}}!'
    )
      .withInput({
        goodbyes: [
          { text: 'goodbye' },
          { text: 'Goodbye' },
          { text: 'GOODBYE' },
        ],
        world: 'world',
      })
      .withMessage('The @index variable is used')
      .toCompileTo('0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!');
  end

  it 'empty block' do
    string = '{{#goodbyes}}{{/goodbyes}}cruel {{world}}!';

    expectTemplate(string)
      .withInput({
        goodbyes: [
          { text: 'goodbye' },
          { text: 'Goodbye' },
          { text: 'GOODBYE' },
        ],
        world: 'world',
      })
      .withMessage('Arrays iterate over the contents when not empty')
      .toCompileTo('cruel world!');

    expectTemplate(string)
      .withInput({
        goodbyes: [],
        world: 'world',
      })
      .withMessage('Arrays ignore the contents when empty')
      .toCompileTo('cruel world!');
  end

  it 'block with complex lookup' do
    expectTemplate('{{#goodbyes}}{{text}} cruel {{../name}}! {{/goodbyes}}')
      .withInput({
        name: 'Alan',
        goodbyes: [
          { text: 'goodbye' },
          { text: 'Goodbye' },
          { text: 'GOODBYE' },
        ],
      })
      .withMessage(
        'Templates can access variables in contexts up the stack with relative path syntax'
      )
      .toCompileTo(
        'goodbye cruel Alan! Goodbye cruel Alan! GOODBYE cruel Alan! '
      );
  end

  it 'multiple blocks with complex lookup' do
    expectTemplate('{{#goodbyes}}{{../name}}{{../name}}{{/goodbyes}}')
      .withInput({
        name: 'Alan',
        goodbyes: [
          { text: 'goodbye' },
          { text: 'Goodbye' },
          { text: 'GOODBYE' },
        ],
      })
      .toCompileTo('AlanAlanAlanAlanAlanAlan');
  end

  it 'block with complex lookup using nested context' do
    expectTemplate(
      '{{#goodbyes}}{{text}} cruel {{foo/../name}}! {{/goodbyes}}'
    ).toThrow(Racc::ParseError);
  end

  it 'block with deep nested complex lookup' do
    expectTemplate(
      '{{#outer}}Goodbye {{#inner}}cruel {{../sibling}} {{../../omg}}{{/inner}}{{/outer}}'
    )
      .withInput({
        omg: 'OMG!',
        outer: [{ sibling: 'sad', inner: [{ text: 'goodbye' }] }],
      })
      .toCompileTo('Goodbye cruel sad OMG!');
  end

  it 'works with cached blocks' do
    skip
    expectTemplate(
      '{{#each person}}{{#with .}}{{first}} {{last}}{{/with}}{{/each}}'
    )
      .withCompileOptions({ data: false })
      .withInput({
        person: [
          { first: 'Alan', last: 'Johnson' },
          { first: 'Alan', last: 'Johnson' },
        ],
      })
      .toCompileTo('Alan JohnsonAlan Johnson');
  end

  describe 'inverted sections' do
    it 'inverted sections with unset value' do
      expectTemplate(
        '{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}'
      )
        .withMessage("Inverted section rendered when value isn't set.")
        .toCompileTo('Right On!');
    end

    it 'inverted section with false value' do
      expectTemplate(
        '{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}'
      )
        .withInput({ goodbyes: false })
        .withMessage('Inverted section rendered when value is false.')
        .toCompileTo('Right On!');
    end

    it 'inverted section with empty set' do
      expectTemplate(
        '{{#goodbyes}}{{this}}{{/goodbyes}}{{^goodbyes}}Right On!{{/goodbyes}}'
      )
        .withInput({ goodbyes: [] })
        .withMessage('Inverted section rendered when value is empty set.')
        .toCompileTo('Right On!');
    end

    it 'block inverted sections' do
      expectTemplate('{{#people}}{{name}}{{^}}{{none}}{{/people}}')
        .withInput({ none: 'No people' })
        .toCompileTo('No people');
    end

    it 'chained inverted sections' do
      expectTemplate('{{#people}}{{name}}{{else if none}}{{none}}{{/people}}')
        .withInput({ none: 'No people' })
        .toCompileTo('No people');

      expectTemplate(
        '{{#people}}{{name}}{{else if nothere}}fail{{else unless nothere}}{{none}}{{/people}}'
      )
        .withInput({ none: 'No people' })
        .toCompileTo('No people');

      expectTemplate(
        '{{#people}}{{name}}{{else if none}}{{none}}{{else}}fail{{/people}}'
      )
        .withInput({ none: 'No people' })
        .toCompileTo('No people');
    end

    it 'chained inverted sections with mismatch' do
      expectTemplate(
        '{{#people}}{{name}}{{else if none}}{{none}}{{/if}}'
      ).toThrow(Racc::ParseError);
    end

    it 'block inverted sections with empty arrays' do
      expectTemplate('{{#people}}{{name}}{{^}}{{none}}{{/people}}')
        .withInput({
          none: 'No people',
          people: [],
        })
        .toCompileTo('No people');
    end
  end

  describe 'standalone sections' do
    it 'block standalone else sections' do
      expectTemplate('{{#people}}\n{{name}}\n{{^}}\n{{none}}\n{{/people}}\n')
        .withInput({ none: 'No people' })
        .toCompileTo('No people\n');

      expectTemplate('{{#none}}\n{{.}}\n{{^}}\n{{none}}\n{{/none}}\n')
        .withInput({ none: 'No people' })
        .toCompileTo('No people\n');

      expectTemplate('{{#people}}\n{{name}}\n{{^}}\n{{none}}\n{{/people}}\n')
        .withInput({ none: 'No people' })
        .toCompileTo('No people\n');
    end

    it 'block standalone else sections can be disabled' do
      expectTemplate('{{#people}}\n{{name}}\n{{^}}\n{{none}}\n{{/people}}\n')
        .withInput({ none: 'No people' })
        .withCompileOptions({ ignoreStandalone: true })
        .toCompileTo('\nNo people\n\n');

      expectTemplate('{{#none}}\n{{.}}\n{{^}}\nFail\n{{/none}}\n')
        .withInput({ none: 'No people' })
        .withCompileOptions({ ignoreStandalone: true })
        .toCompileTo('\nNo people\n\n');
    end

    it 'block standalone chained else sections' do
      expectTemplate(
        '{{#people}}\n{{name}}\n{{else if none}}\n{{none}}\n{{/people}}\n'
      )
        .withInput({ none: 'No people' })
        .toCompileTo('No people\n');

      expectTemplate(
        '{{#people}}\n{{name}}\n{{else if none}}\n{{none}}\n{{^}}\n{{/people}}\n'
      )
        .withInput({ none: 'No people' })
        .toCompileTo('No people\n');
    end

    it 'should handle nesting' do
      expectTemplate('{{#data}}\n{{#if true}}\n{{.}}\n{{/if}}\n{{/data}}\nOK.')
        .withInput({
          data: [1, 3, 5],
        })
        .toCompileTo('1\n3\n5\nOK.');
    end
  end

  describe 'compat mode' do
    it 'block with deep recursive lookup lookup' do
      skip
      expectTemplate(
        '{{#outer}}Goodbye {{#inner}}cruel {{omg}}{{/inner}}{{/outer}}'
      )
        .withInput({ omg: 'OMG!', outer: [{ inner: [{ text: 'goodbye' }] }] })
        .withCompileOptions({ compat: true })
        .toCompileTo('Goodbye cruel OMG!');
    end

    it 'block with deep recursive pathed lookup' do
      skip
      expectTemplate(
        '{{#outer}}Goodbye {{#inner}}cruel {{omg.yes}}{{/inner}}{{/outer}}'
      )
        .withInput({
          omg: { yes: 'OMG!' },
          outer: [{ inner: [{ yes: 'no', text: 'goodbye' }] }],
        })
        .withCompileOptions({ compat: true })
        .toCompileTo('Goodbye cruel OMG!');
    end

    it 'block with missed recursive lookup' do
      skip
      expectTemplate(
        '{{#outer}}Goodbye {{#inner}}cruel {{omg.yes}}{{/inner}}{{/outer}}'
      )
        .withInput({
          omg: { no: 'OMG!' },
          outer: [{ inner: [{ yes: 'no', text: 'goodbye' }] }],
        })
        .withCompileOptions({ compat: true })
        .toCompileTo('Goodbye cruel ');
    end
  end

  describe 'decorators' do
    it 'should apply mustache decorators' do
      skip
      expectTemplate('{{#helper}}{{*decorator}}{{/helper}}')
        .withHelper('helper', lambda { |options|
          return options.fn.run;
        })
        .withDecorator('decorator', lambda { |fn|
          fn.run = 'success';
          return fn;
        })
        .toCompileTo('success');
    end

    it 'should apply allow undefined return' do
      skip
      expectTemplate('{{#helper}}{{*decorator}}suc{{/helper}}')
        .withHelper('helper', lambda { |options|
          return options.fn + options.fn.run;
        })
        .withDecorator('decorator', lambda { |fn|
          fn.run = 'cess';
        })
        .toCompileTo('success');
    end

    it 'should apply block decorators' do
      skip
      expectTemplate(
        '{{#helper}}{{#*decorator}}success{{/decorator}}{{/helper}}'
      )
        .withHelper('helper', lambda { |options|
          return options.fn.run;
        })
        .withDecorator('decorator', lambda { |fn, _props, _container, options|
          fn.run = options.fn;
          return fn;
        })
        .toCompileTo('success');
    end

    it 'should support nested decorators' do
      skip
      expectTemplate(
        '{{#helper}}{{#*decorator}}{{#*nested}}suc{{/nested}}cess{{/decorator}}{{/helper}}'
      )
        .withHelper('helper', lambda { |options|
          return options.fn.run;
        })
        .withDecorators({
          decorator: lambda { |fn, _props, _container, options|
            fn.run = options.fn.nested + options.fn;
            return fn;
          },
          nested: lambda { |_fn, props, _container, options|
            props.nested = options.fn;
          },
        })
        .toCompileTo('success');
    end

    it 'should apply multiple decorators' do
      skip
      expectTemplate(
        '{{#helper}}{{#*decorator}}suc{{/decorator}}{{#*decorator}}cess{{/decorator}}{{/helper}}'
      )
        .withHelper('helper', lambda { |options|
          return options.fn.run;
        })
        .withDecorator('decorator', lambda { |fn, _props, _container, options|
          fn.run = (fn.run || '') + options.fn;
          return fn;
        })
        .toCompileTo('success');
    end

    it 'should access parent variables' do
      skip
      expectTemplate('{{#helper}}{{*decorator foo}}{{/helper}}')
        .withHelper('helper', lambda { |options|
          return options.fn.run;
        })
        .withDecorator('decorator', lambda { |fn, _props, _container, options|
          fn.run = options.args;
          return fn;
        })
        .withInput({ foo: 'success' })
        .toCompileTo('success');
    end

    it 'should work with root program' do
      skip
      run = false;
      expectTemplate('{{*decorator "success"}}')
        .withDecorator('decorator', lambda { |fn, _props, _container, options|
          equals(options.args[0], 'success');
          run = true;
          return fn;
        })
        .withInput({ foo: 'success' })
        .toCompileTo('');
      equals(run, true);
    end

    it 'should fail when accessing variables from root' do
      skip
      run = false;
      expectTemplate('{{*decorator foo}}')
        .withDecorator('decorator', lambda { |fn, _props, _container, options|
          equals(options.args[0], undefined);
          run = true;
          return fn;
        })
        .withInput({ foo: 'fail' })
        .toCompileTo('');
      equals(run, true);
    end

    describe 'registration' do
      it 'unregisters' do
        skip
        handlebarsEnv.decorators = {};

        handlebarsEnv.registerDecorator('foo', lambda do
          skip
          return 'fail';
        end)

        equals(!!handlebarsEnv.decorators.foo, true);
        handlebarsEnv.unregisterDecorator('foo');
        equals(handlebarsEnv.decorators.foo, undefined);
      end

      it 'allows multiple globals' do
        skip
        handlebarsEnv.decorators = {};

        handlebarsEnv.registerDecorator({
          foo: -> {},
          bar: -> {},
        })

        equals(!!handlebarsEnv.decorators.foo, true);
        equals(!!handlebarsEnv.decorators.bar, true);
        handlebarsEnv.unregisterDecorator('foo');
        handlebarsEnv.unregisterDecorator('bar');
        equals(handlebarsEnv.decorators.foo, undefined);
        equals(handlebarsEnv.decorators.bar, undefined);
      end

      it 'fails with multiple and args' do
        skip
        shouldThrow(
          lambda {
            handlebarsEnv.registerDecorator(
              {
                world: lambda {
                  return 'world!';
                },
                testHelper: lambda {
                  return 'found it!';
                },
              },
              {}
            );
          },
          Error,
          'Arg not supported with multiple decorators'
        );
      end
    end
  end
end
