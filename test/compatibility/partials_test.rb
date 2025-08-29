# frozen_string_literal: true

require "test_helper"

# Based on spec/partials.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/partials.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'partials' do
  it 'basic partials' do
    string = 'Dudes: {{#dudes}}{{> dude}}{{/dudes}}';
    partial = '{{name}} ({{url}}) ';
    hash = {
      dudes: [
        { name: 'Yehuda', url: 'http://yehuda' },
        { name: 'Alan', url: 'http://alan' },
      ],
    };

    expectTemplate(string)
      .withInput(hash)
      .withPartials({ dude: partial })
      .toCompileTo('Dudes: Yehuda (http://yehuda) Alan (http://alan) ');

    expectTemplate(string)
      .withInput(hash)
      .withPartials({ dude: partial })
      .withRuntimeOptions({ data: false })
      .withCompileOptions({ data: false })
      .toCompileTo('Dudes: Yehuda (http://yehuda) Alan (http://alan) ');
  end

  it 'dynamic partials' do
    string = 'Dudes: {{#dudes}}{{> (partial)}}{{/dudes}}';
    partial = '{{name}} ({{url}}) ';
    hash = {
      dudes: [
        { name: 'Yehuda', url: 'http://yehuda' },
        { name: 'Alan', url: 'http://alan' },
      ],
    };
    helpers = {
      partial: lambda {
        return 'dude';
      },
    };

    expectTemplate(string)
      .withInput(hash)
      .withHelpers(helpers)
      .withPartials({ dude: partial })
      .toCompileTo('Dudes: Yehuda (http://yehuda) Alan (http://alan) ');

    expectTemplate(string)
      .withInput(hash)
      .withHelpers(helpers)
      .withPartials({ dude: partial })
      .withRuntimeOptions({ data: false })
      .withCompileOptions({ data: false })
      .toCompileTo('Dudes: Yehuda (http://yehuda) Alan (http://alan) ');
  end

  it 'failing dynamic partials' do
    expectTemplate('Dudes: {{#dudes}}{{> (partial)}}{{/dudes}}')
      .withInput({
        dudes: [
          { name: 'Yehuda', url: 'http://yehuda' },
          { name: 'Alan', url: 'http://alan' },
        ],
      })
      .withHelper('partial', lambda {
        return 'missing';
      })
      .withPartial('dude', '{{name}} ({{url}}) ')
      .toThrow(
        KeyError,
        'The partial "missing" could not be found'
      );
  end

  it 'partials with context' do
    expectTemplate('Dudes: {{>dude dudes}}')
      .withInput({
        dudes: [
          { name: 'Yehuda', url: 'http://yehuda' },
          { name: 'Alan', url: 'http://alan' },
        ],
      })
      .withPartial('dude', '{{#this}}{{name}} ({{url}}) {{/this}}')
      .withMessage('Partials can be passed a context')
      .toCompileTo('Dudes: Yehuda (http://yehuda) Alan (http://alan) ');
  end

  it 'partials with no context' do
    skip
    var partial = '{{name}} ({{url}}) ';
    var hash = {
      dudes: [
        { name: 'Yehuda', url: 'http://yehuda' },
        { name: 'Alan', url: 'http://alan' },
      ],
    };

    expectTemplate('Dudes: {{#dudes}}{{>dude}}{{/dudes}}')
      .withInput(hash)
      .withPartial('dude', partial)
      .withCompileOptions({ explicitPartialContext: true })
      .toCompileTo('Dudes:  ()  () ');

    expectTemplate('Dudes: {{#dudes}}{{>dude name="foo"}}{{/dudes}}')
      .withInput(hash)
      .withPartial('dude', partial)
      .withCompileOptions({ explicitPartialContext: true })
      .toCompileTo('Dudes: foo () foo () ');
  end

  it 'partials with string context' do
    expectTemplate('Dudes: {{>dude "dudes"}}')
      .withPartial('dude', '{{.}}')
      .toCompileTo('Dudes: dudes');
  end

  it 'partials with undefined context' do
    expectTemplate('Dudes: {{>dude dudes}}')
      .withPartial('dude', '{{foo}} Empty')
      .toCompileTo('Dudes:  Empty');
  end

  it 'partials with duplicate parameters' do
    skip
    expectTemplate('Dudes: {{>dude dudes foo bar=baz}}').toThrow(
      Error,
      'Unsupported number of partial arguments: 2 - 1:7'
    );
  end

  it 'partials with parameters' do
    skip
    expectTemplate('Dudes: {{#dudes}}{{> dude others=..}}{{/dudes}}')
      .withInput({
        foo: 'bar',
        dudes: [
          { name: 'Yehuda', url: 'http://yehuda' },
          { name: 'Alan', url: 'http://alan' },
        ],
      })
      .withPartial('dude', '{{others.foo}}{{name}} ({{url}}) ')
      .withMessage('Basic partials output based on current context.')
      .toCompileTo('Dudes: barYehuda (http://yehuda) barAlan (http://alan) ');
  end

  it 'partial in a partial' do
    expectTemplate('Dudes: {{#dudes}}{{>dude}}{{/dudes}}')
      .withInput({
        dudes: [
          { name: 'Yehuda', url: 'http://yehuda' },
          { name: 'Alan', url: 'http://alan' },
        ],
      })
      .withPartials({
        dude: '{{name}} {{> url}} ',
        url: '<a href="{{url}}">{{url}}</a>',
      })
      .withMessage('Partials are rendered inside of other partials')
      .toCompileTo(
        'Dudes: Yehuda <a href="http://yehuda">http://yehuda</a> Alan <a href="http://alan">http://alan</a> '
      );
  end

  it 'rendering undefined partial throws an exception' do
    expectTemplate('{{> whatever}}').toThrow(
      KeyError,
      'The partial "whatever" could not be found'
    );
  end

  it 'registering undefined partial throws an exception' do
    skip
    shouldThrow(
      lambda {
        var undef_;
        handlebarsEnv.registerPartial('undefined_test', undef_);
      },
      Handlebars.Exception,
      'Attempting to register a partial called "undefined_test" as undefined'
    );
  end

  it 'rendering template partial in vm mode throws an exception' do
    expectTemplate('{{> whatever}}').toThrow(
      KeyError,
      'The partial "whatever" could not be found'
    );
  end

  it 'rendering function partial in vm mode' do
    skip
    function partial(context) {
      return context.name + ' (' + context.url + ') ';
    }
    expectTemplate('Dudes: {{#dudes}}{{> dude}}{{/dudes}}')
      .withInput({
        dudes: [
          { name: 'Yehuda', url: 'http://yehuda' },
          { name: 'Alan', url: 'http://alan' },
        ],
      })
      .withPartial('dude', partial)
      .withMessage('Function partials output based in VM.')
      .toCompileTo('Dudes: Yehuda (http://yehuda) Alan (http://alan) ');
  end

  it 'GH-14: a partial preceding a selector' do
    expectTemplate('Dudes: {{>dude}} {{anotherDude}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('dude', '{{name}}')
      .withMessage('Regular selectors can follow a partial')
      .toCompileTo('Dudes: Jeepers Creepers');
  end

  it 'Partials with slash paths' do
    skip
    expectTemplate('Dudes: {{> shared/dude}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('shared/dude', '{{name}}')
      .withMessage('Partials can use literal paths')
      .toCompileTo('Dudes: Jeepers');
  end

  it 'Partials with slash and point paths' do
    skip
    expectTemplate('Dudes: {{> shared/dude.thing}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('shared/dude.thing', '{{name}}')
      .withMessage('Partials can use literal with points in paths')
      .toCompileTo('Dudes: Jeepers');
  end

  it 'Global Partials' do
    skip
    handlebarsEnv.registerPartial('globalTest', '{{anotherDude}}');

    expectTemplate('Dudes: {{> shared/dude}} {{> globalTest}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('shared/dude', '{{name}}')
      .withMessage('Partials can use globals or passed')
      .toCompileTo('Dudes: Jeepers Creepers');

    handlebarsEnv.unregisterPartial('globalTest');
    equals(handlebarsEnv.partials.globalTest, undefined);
  end

  it 'Multiple partial registration' do
    skip
    handlebarsEnv.registerPartial({
      'shared/dude': '{{name}}',
      globalTest: '{{anotherDude}}',
    });

    expectTemplate('Dudes: {{> shared/dude}} {{> globalTest}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('notused', 'notused') # trick the test bench into running with partials enabled
      .withMessage('Partials can use globals or passed')
      .toCompileTo('Dudes: Jeepers Creepers');
  end

  it 'Partials with integer path' do
    expectTemplate('Dudes: {{> 404}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial(404, '{{name}}')
      .withMessage('Partials can use literal paths')
      .toCompileTo('Dudes: Jeepers');
  end

  it 'Partials with complex path' do
    skip
    expectTemplate('Dudes: {{> 404/asdf?.bar}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('404/asdf?.bar', '{{name}}')
      .withMessage('Partials can use literal paths')
      .toCompileTo('Dudes: Jeepers');
  end

  it 'Partials with escaped' do
    expectTemplate('Dudes: {{> [+404/asdf?.bar]}}')
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('+404/asdf?.bar', '{{name}}')
      .withMessage('Partials can use literal paths')
      .toCompileTo('Dudes: Jeepers');
  end

  it 'Partials with string' do
    expectTemplate("Dudes: {{> '+404/asdf?.bar'}}")
      .withInput({ name: 'Jeepers', anotherDude: 'Creepers' })
      .withPartial('+404/asdf?.bar', '{{name}}')
      .withMessage('Partials can use literal paths')
      .toCompileTo('Dudes: Jeepers');
  end

  it 'should handle empty partial' do
    skip
    expectTemplate('Dudes: {{#dudes}}{{> dude}}{{/dudes}}')
      .withInput({
        dudes: [
          { name: 'Yehuda', url: 'http://yehuda' },
          { name: 'Alan', url: 'http://alan' },
        ],
      })
      .withPartial('dude', '')
      .toCompileTo('Dudes: ');
  end

  it 'throw on missing partial' do
    skip
    var compile = handlebarsEnv.compile;
    var compileWithPartial = CompilerContext.compileWithPartial;
    handlebarsEnv.compile = undefined;
    CompilerContext.compileWithPartial = CompilerContext.compile;
    expectTemplate('{{> dude}}')
      .withPartials({ dude: 'fail' })
      .toThrow(Error, /The partial dude could not be compiled/);
    handlebarsEnv.compile = compile;
    CompilerContext.compileWithPartial = compileWithPartial;
  end

  describe 'partial blocks' do
    it 'should render partial block as default' do
      skip
      expectTemplate('{{#> dude}}success{{/dude}}').toCompileTo('success');
    end

    it 'should execute default block with proper context' do
      skip
      expectTemplate('{{#> dude context}}{{value}}{{/dude}}')
        .withInput({ context: { value: 'success' } })
        .toCompileTo('success');
    end

    it 'should propagate block parameters to default block' do
      skip
      expectTemplate(
        '{{#with context as |me|}}{{#> dude}}{{me.value}}{{/dude}}{{/with}}'
      )
        .withInput({ context: { value: 'success' } })
        .toCompileTo('success');
    end

    it 'should not use partial block if partial exists' do
      skip
      expectTemplate('{{#> dude}}fail{{/dude}}')
        .withPartials({ dude: 'success' })
        .toCompileTo('success');
    end

    it 'should render block from partial' do
      skip
      expectTemplate('{{#> dude}}success{{/dude}}')
        .withPartials({ dude: '{{> @partial-block }}' })
        .toCompileTo('success');
    end

    it 'should be able to render the partial-block twice' do
      skip
      expectTemplate('{{#> dude}}success{{/dude}}')
        .withPartials({ dude: '{{> @partial-block }} {{> @partial-block }}' })
        .toCompileTo('success success');
    end

    it 'should render block from partial with context' do
      skip
      expectTemplate('{{#> dude}}{{value}}{{/dude}}')
        .withInput({ context: { value: 'success' } })
        .withPartials({
          dude: '{{#with context}}{{> @partial-block }}{{/with}}',
        })
        .toCompileTo('success');
    end

    it 'should be able to access the @data frame from a partial-block' do
      skip
      expectTemplate('{{#> dude}}in-block: {{@root/value}}{{/dude}}')
        .withInput({ value: 'success' })
        .withPartials({
          dude: '<code>before-block: {{@root/value}} {{>   @partial-block }}</code>',
        })
        .toCompileTo('<code>before-block: success in-block: success</code>');
    end

    it 'should allow the #each-helper to be used along with partial-blocks' do
      skip
      expectTemplate(
        '<template>{{#> list value}}value = {{.}}{{/list}}</template>'
      )
        .withInput({
          value: ['a', 'b', 'c'],
        })
        .withPartials({
          list: '<list>{{#each .}}<item>{{> @partial-block}}</item>{{/each}}</list>',
        })
        .toCompileTo(
          '<template><list><item>value = a</item><item>value = b</item><item>value = c</item></list></template>'
        );
    end

    it 'should render block from partial with context (twice)' do
      skip
      expectTemplate('{{#> dude}}{{value}}{{/dude}}')
        .withInput({ context: { value: 'success' } })
        .withPartials({
          dude: '{{#with context}}{{> @partial-block }} {{> @partial-block }}{{/with}}',
        })
        .toCompileTo('success success');
    end

    it 'should render block from partial with context' do
      skip
      expectTemplate('{{#> dude}}{{../context/value}}{{/dude}}')
        .withInput({ context: { value: 'success' } })
        .withPartials({
          dude: '{{#with context}}{{> @partial-block }}{{/with}}',
        })
        .toCompileTo('success');
    end

    it 'should render block from partial with block params' do
      skip
      expectTemplate(
        '{{#with context as |me|}}{{#> dude}}{{me.value}}{{/dude}}{{/with}}'
      )
        .withInput({ context: { value: 'success' } })
        .withPartials({ dude: '{{> @partial-block }}' })
        .toCompileTo('success');
    end

    it 'should render nested partial blocks' do
      skip
      expectTemplate('<template>{{#> outer}}{{value}}{{/outer}}</template>')
        .withInput({ value: 'success' })
        .withPartials({
          outer:
            '<outer>{{#> nested}}<outer-block>{{> @partial-block}}</outer-block>{{/nested}}</outer>',
          nested: '<nested>{{> @partial-block}}</nested>',
        })
        .toCompileTo(
          '<template><outer><nested><outer-block>success</outer-block></nested></outer></template>'
        );
    end

    it 'should render nested partial blocks at different nesting levels' do
      skip
      expectTemplate('<template>{{#> outer}}{{value}}{{/outer}}</template>')
        .withInput({ value: 'success' })
        .withPartials({
          outer:
            '<outer>{{#> nested}}<outer-block>{{> @partial-block}}</outer-block>{{/nested}}{{> @partial-block}}</outer>',
          nested: '<nested>{{> @partial-block}}</nested>',
        })
        .toCompileTo(
          '<template><outer><nested><outer-block>success</outer-block></nested>success</outer></template>'
        );
    end

    it 'should render nested partial blocks at different nesting levels (twice)' do
      skip
      expectTemplate('<template>{{#> outer}}{{value}}{{/outer}}</template>')
        .withInput({ value: 'success' })
        .withPartials({
          outer:
            '<outer>{{#> nested}}<outer-block>{{> @partial-block}} {{> @partial-block}}</outer-block>{{/nested}}{{> @partial-block}}+{{> @partial-block}}</outer>',
          nested: '<nested>{{> @partial-block}}</nested>',
        })
        .toCompileTo(
          '<template><outer><nested><outer-block>success success</outer-block></nested>success+success</outer></template>'
        );
    end

    it 'should render nested partial blocks (twice at each level)' do
      skip
      expectTemplate('<template>{{#> outer}}{{value}}{{/outer}}</template>')
        .withInput({ value: 'success' })
        .withPartials({
          outer:
            '<outer>{{#> nested}}<outer-block>{{> @partial-block}} {{> @partial-block}}</outer-block>{{/nested}}</outer>',
          nested: '<nested>{{> @partial-block}}{{> @partial-block}}</nested>',
        })
        .toCompileTo(
          '<template><outer>' +
            '<nested><outer-block>success success</outer-block><outer-block>success success</outer-block></nested>' +
            '</outer></template>'
        );
    end
  end

  describe 'inline partials' do
    it 'should define inline partials for template' do
      skip
      expectTemplate(
        '{{#*inline "myPartial"}}success{{/inline}}{{> myPartial}}'
      ).toCompileTo('success');
    end

    it 'should overwrite multiple partials in the same template' do
      skip
      expectTemplate(
        '{{#*inline "myPartial"}}fail{{/inline}}{{#*inline "myPartial"}}success{{/inline}}{{> myPartial}}'
      ).toCompileTo('success');
    end

    it 'should define inline partials for block' do
      skip
      expectTemplate(
        '{{#with .}}{{#*inline "myPartial"}}success{{/inline}}{{> myPartial}}{{/with}}'
      ).toCompileTo('success');

      expectTemplate(
        '{{#with .}}{{#*inline "myPartial"}}success{{/inline}}{{/with}}{{> myPartial}}'
      ).toThrow(Error, /"myPartial" could not/);
    end

    it 'should override global partials' do
      skip
      expectTemplate(
        '{{#*inline "myPartial"}}success{{/inline}}{{> myPartial}}'
      )
        .withPartials({
          myPartial: lambda {
            return 'fail';
          },
        })
        .toCompileTo('success');
    end

    it 'should override template partials' do
      skip
      expectTemplate(
        '{{#*inline "myPartial"}}fail{{/inline}}{{#with .}}{{#*inline "myPartial"}}success{{/inline}}{{> myPartial}}{{/with}}'
      ).toCompileTo('success');
    end

    it 'should override partials down the entire stack' do
      skip
      expectTemplate(
        '{{#with .}}{{#*inline "myPartial"}}success{{/inline}}{{#with .}}{{#with .}}{{> myPartial}}{{/with}}{{/with}}{{/with}}'
      ).toCompileTo('success');
    end

    it 'should define inline partials for partial call' do
      skip
      expectTemplate('{{#*inline "myPartial"}}success{{/inline}}{{> dude}}')
        .withPartials({ dude: '{{> myPartial }}' })
        .toCompileTo('success');
    end

    it 'should define inline partials in partial block call' do
      skip
      expectTemplate(
        '{{#> dude}}{{#*inline "myPartial"}}success{{/inline}}{{/dude}}'
      )
        .withPartials({ dude: '{{> myPartial }}' })
        .toCompileTo('success');
    end

    it 'should render nested inline partials' do
      skip
      expectTemplate(
        '{{#*inline "outer"}}{{#>inner}}<outer-block>{{>@partial-block}}</outer-block>{{/inner}}{{/inline}}' +
          '{{#*inline "inner"}}<inner>{{>@partial-block}}</inner>{{/inline}}' +
          '{{#>outer}}{{value}}{{/outer}}'
      )
        .withInput({ value: 'success' })
        .toCompileTo('<inner><outer-block>success</outer-block></inner>');
    end

    it 'should render nested inline partials with partial-blocks on different nesting levels' do
      skip
      expectTemplate(
        '{{#*inline "outer"}}{{#>inner}}<outer-block>{{>@partial-block}}</outer-block>{{/inner}}{{>@partial-block}}{{/inline}}' +
          '{{#*inline "inner"}}<inner>{{>@partial-block}}</inner>{{/inline}}' +
          '{{#>outer}}{{value}}{{/outer}}'
      )
        .withInput({ value: 'success' })
        .toCompileTo(
          '<inner><outer-block>success</outer-block></inner>success'
        );
    end

    it 'should render nested inline partials (twice at each level)' do
      skip
      expectTemplate(
        '{{#*inline "outer"}}{{#>inner}}<outer-block>{{>@partial-block}} {{>@partial-block}}</outer-block>{{/inner}}{{/inline}}' +
          '{{#*inline "inner"}}<inner>{{>@partial-block}}{{>@partial-block}}</inner>{{/inline}}' +
          '{{#>outer}}{{value}}{{/outer}}'
      )
        .withInput({ value: 'success' })
        .toCompileTo(
          '<inner><outer-block>success success</outer-block><outer-block>success success</outer-block></inner>'
        );
    end
  end

  it 'should pass compiler flags' do
    skip
    if Handlebars.compile
      var env = Handlebars.create;
      env.registerPartial('partial', '{{foo}}');
      var template = env.compile('{{foo}} {{> partial}}', { noEscape: true });
      equal(template.call({ foo: '<' }), '< <');
    end
  end

  describe 'standalone partials' do
    it 'indented partials' do
      skip
      expectTemplate('Dudes:\n{{#dudes}}\n  {{>dude}}\n{{/dudes}}')
        .withInput({
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartial('dude', '{{name}}\n')
        .toCompileTo('Dudes:\n  Yehuda\n  Alan\n');
    end

    it 'nested indented partials' do
      skip
      expectTemplate('Dudes:\n{{#dudes}}\n  {{>dude}}\n{{/dudes}}')
        .withInput({
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartials({
          dude: '{{name}}\n {{> url}}',
          url: '{{url}}!\n',
        })
        .toCompileTo(
          'Dudes:\n  Yehuda\n   http://yehuda!\n  Alan\n   http://alan!\n'
        );
    end

    it 'prevent nested indented partials' do
      skip
      expectTemplate('Dudes:\n{{#dudes}}\n  {{>dude}}\n{{/dudes}}')
        .withInput({
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartials({
          dude: '{{name}}\n {{> url}}',
          url: '{{url}}!\n',
        })
        .withCompileOptions({ preventIndent: true })
        .toCompileTo(
          'Dudes:\n  Yehuda\n http://yehuda!\n  Alan\n http://alan!\n'
        );
    end
  end

  describe 'compat mode' do
    it 'partials can access parents' do
      skip
      expectTemplate('Dudes: {{#dudes}}{{> dude}}{{/dudes}}')
        .withInput({
          root: 'yes',
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartials({ dude: '{{name}} ({{url}}) {{root}} ' })
        .withCompileOptions({ compat: true })
        .toCompileTo(
          'Dudes: Yehuda (http://yehuda) yes Alan (http://alan) yes '
        );
    end

    it 'partials can access parents with custom context' do
      skip
      expectTemplate('Dudes: {{#dudes}}{{> dude "test"}}{{/dudes}}')
        .withInput({
          root: 'yes',
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartials({ dude: '{{name}} ({{url}}) {{root}} ' })
        .withCompileOptions({ compat: true })
        .toCompileTo(
          'Dudes: Yehuda (http://yehuda) yes Alan (http://alan) yes '
        );
    end

    it 'partials can access parents without data' do
      skip
      expectTemplate('Dudes: {{#dudes}}{{> dude}}{{/dudes}}')
        .withInput({
          root: 'yes',
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartials({ dude: '{{name}} ({{url}}) {{root}} ' })
        .withRuntimeOptions({ data: false })
        .withCompileOptions({ data: false, compat: true })
        .toCompileTo(
          'Dudes: Yehuda (http://yehuda) yes Alan (http://alan) yes '
        );
    end

    it 'partials inherit compat' do
      skip
      expectTemplate('Dudes: {{> dude}}')
        .withInput({
          root: 'yes',
          dudes: [
            { name: 'Yehuda', url: 'http://yehuda' },
            { name: 'Alan', url: 'http://alan' },
          ],
        })
        .withPartials({
          dude: '{{#dudes}}{{name}} ({{url}}) {{root}} {{/dudes}}',
        })
        .withCompileOptions({ compat: true })
        .toCompileTo(
          'Dudes: Yehuda (http://yehuda) yes Alan (http://alan) yes '
        );
    end
  end
end
