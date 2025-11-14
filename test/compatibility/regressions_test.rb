# frozen_string_literal: true

require "test_helper"

# Based on spec/regressions.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/regressions.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'Regressions' do
  let(:undefined) { nil }
  let(:null) { nil }

  it 'GH-94: Cannot read property of undefined' do
    expectTemplate('{{#books}}{{title}}{{author.name}}{{/books}}')
      .withInput({
        books: [
          {
            title: 'The origin of species',
            author: {
              name: 'Charles Darwin',
            },
          },
          {
            title: 'Lazarillo de Tormes',
          },
        ],
      })
      .withMessage('Renders without an undefined property error')
      .toCompileTo('The origin of speciesCharles DarwinLazarillo de Tormes');
  end

  it "GH-150: Inverted sections print when they shouldn't" do
    string = '{{^set}}not set{{/set}} :: {{#set}}set{{/set}}';

    expectTemplate(string)
      .withMessage(
        "inverted sections run when property isn't present in context"
      )
      .toCompileTo('not set :: ');

    expectTemplate(string)
      .withInput({ set: undefined })
      .withMessage('inverted sections run when property is undefined')
      .toCompileTo('not set :: ');

    expectTemplate(string)
      .withInput({ set: false })
      .withMessage('inverted sections run when property is false')
      .toCompileTo('not set :: ');

    expectTemplate(string)
      .withInput({ set: true })
      .withMessage("inverted sections don't run when property is true")
      .toCompileTo(' :: set');
  end

  it 'GH-158: Using array index twice, breaks the template' do
    expectTemplate('{{arr.[0]}}, {{arr.[1]}}')
      .withInput({ arr: [1, 2] })
      .withMessage('it works as expected')
      .toCompileTo('1, 2');
  end

  it "bug reported by @fat where lambdas weren't being properly resolved" do
    string =
      '<strong>This is a slightly more complicated {{thing}}.</strong>.\n' +
      '{{! Just ignore this business. }}\n' +
      'Check this out:\n' +
      '{{#hasThings}}\n' +
      '<ul>\n' +
      '{{#things}}\n' +
      '<li class={{className}}>{{word}}</li>\n' +
      '{{/things}}</ul>.\n' +
      '{{/hasThings}}\n' +
      '{{^hasThings}}\n' +
      '\n' +
      '<small>Nothing to check out...</small>\n' +
      '{{/hasThings}}';

    data = {
      thing: lambda {
        return 'blah';
      },
      things: [
        { className: 'one', word: '@fat' },
        { className: 'two', word: '@dhg' },
        { className: 'three', word: '@sayrer' },
      ],
      hasThings: lambda {
        return true;
      },
    };

    output =
      '<strong>This is a slightly more complicated blah.</strong>.\n' +
      'Check this out:\n' +
      '<ul>\n' +
      '<li class=one>@fat</li>\n' +
      '<li class=two>@dhg</li>\n' +
      '<li class=three>@sayrer</li>\n' +
      '</ul>.\n';

    expectTemplate(string).withInput(data).toCompileTo(output);
  end

  it 'GH-408: Multiple loops fail' do
    expectTemplate(
      '{{#.}}{{name}}{{/.}}{{#.}}{{name}}{{/.}}{{#.}}{{name}}{{/.}}'
    )
      .withInput([
        { name: 'John Doe', location: { city: 'Chicago' } },
        { name: 'Jane Doe', location: { city: 'New York' } },
      ])
      .withMessage('It should output multiple times')
      .toCompileTo('John DoeJane DoeJohn DoeJane DoeJohn DoeJane Doe');
  end

  it 'GS-428: Nested if else rendering' do
    succeedingTemplate =
      '{{#inverse}} {{#blk}} Unexpected {{/blk}} {{else}}  {{#blk}} Expected {{/blk}} {{/inverse}}';
    failingTemplate =
      '{{#inverse}} {{#blk}} Unexpected {{/blk}} {{else}} {{#blk}} Expected {{/blk}} {{/inverse}}';

    helpers = {
      blk: lambda { |block|
        return block.fn('');
      },
      inverse: lambda { |block|
        return block.inverse('');
      },
    };

    expectTemplate(succeedingTemplate)
      .withHelpers(helpers)
      .toCompileTo('   Expected  ');

    expectTemplate(failingTemplate)
      .withHelpers(helpers)
      .toCompileTo('  Expected  ');
  end

  it 'GH-458: Scoped this identifier' do
    expectTemplate('{{./foo}}').withInput({ foo: 'bar' }).toCompileTo('bar');
  end

  it 'GH-375: Unicode line terminators' do
    expectTemplate('\u2028').toCompileTo('\u2028');
  end

  it 'GH-534: Object prototype aliases' do
    skip "Ruby does not have object prototypes"
    Object.prototype[0xd834] = true;

    expectTemplate('{{foo}}').withInput({ foo: 'bar' }).toCompileTo('bar');

    delete Object.prototype[0xd834];
  end

  it 'GH-437: Matching escaping' do
    expectTemplate('{{{a}}').toThrow(StandardError, /Parse error on/);
    expectTemplate('{{a}}}').toThrow(StandardError, /Parse error on/);
  end

  it 'GH-676: Using array in escaping mustache fails' do
    data = { arr: [1, 2] };

    expectTemplate('{{arr}}')
      .withInput(data)
      .withMessage('it works as expected')
      .toCompileTo(data[:arr].to_s);
  end

  # NOTE: This test was changed from the original to have a decimal in the
  # second amount, which matches the mustache man page. In Javascript, bot
  # amounts will be floats so the use the same string rendering method. Not so
  # in Ruby.
  it 'Mustache man page' do
    expectTemplate(
      'Hello {{name}}. You have just won ${{value}}!{{#in_ca}} Well, ${{taxed_value}}, after taxes.{{/in_ca}}'
    )
      .withInput({
        name: 'Chris',
        value: 10_000,
        taxed_value: 10_000 - (10_000 * 0.4),
        in_ca: true,
      })
      .withMessage('the hello world mustache example works')
      .toCompileTo(
        'Hello Chris. You have just won $10000! Well, $6000.0, after taxes.'
      );
  end

  it 'GH-731: zero context rendering' do
    expectTemplate('{{#foo}} This is {{bar}} ~ {{/foo}}')
      .withInput({
        foo: 0,
        bar: 'OK',
      })
      .toCompileTo(' This is  ~ ');
  end

  it 'GH-820: zero pathed rendering' do
    expectTemplate('{{foo.bar}}').withInput({ foo: 0 }).toCompileTo('');
  end

  it 'GH-837: undefined values for helpers' do
    expectTemplate('{{str bar.baz}}')
      .withHelpers({
        str: lambda { |value|
          return value.inspect;
        },
      })
      .toCompileTo('nil');
  end

  it 'GH-926: Depths and de-dupe' do
    expectTemplate(
      '{{#if dater}}{{#each data}}{{../name}}{{/each}}{{else}}{{#each notData}}{{../name}}{{/each}}{{/if}}'
    )
      .withInput({
        name: 'foo',
        data: [1],
        notData: [1],
      })
      .toCompileTo('foo');
  end

  it 'GH-1021: Each empty string key' do
    expectTemplate('{{#each data}}Key: {{@key}}\n{{/each}}')
      .withInput({
        data: {
          '': 'foo',
          name: 'Chris',
          value: 10_000,
        },
      })
      .toCompileTo('Key: \nKey: name\nKey: value\n');
  end

  it 'GH-1054: Should handle simple safe string responses' do
    expectTemplate('{{#wrap}}{{>partial}}{{/wrap}}')
      .withHelpers({
        wrap: lambda { |options|
          return Haparanda::HandlebarsProcessor::SafeString.new(options.fn);
        },
      })
      .withPartials({
        partial: '{{#wrap}}<partial>{{/wrap}}',
      })
      .toCompileTo('<partial>');
  end

  it 'GH-1065: Sparse arrays' do
    skip "Ruby does not have real sparse arrays"
    array = [];
    array[1] = 'foo';
    array[3] = 'bar';
    expectTemplate('{{#each array}}{{@index}}{{.}}{{/each}}')
      .withInput({ array: array })
      .toCompileTo('1foo3bar');
  end

  it 'GH-1093: Undefined helper context' do
    expectTemplate('{{#each obj}}{{{helper}}}{{.}}{{/each}}')
      .withInput({ obj: { foo: undefined, bar: 'bat' } })
      .withHelpers({
        helper: lambda {
          if this.nil?
            "not"
          else
            "found"
          end
        },
      })
      .toCompileTo('notfoundbat');
  end

  it 'should support multiple levels of inline partials' do
    expectTemplate(
      '{{#> layout}}{{#*inline "subcontent"}}subcontent{{/inline}}{{/layout}}'
    )
      .withPartials({
        doctype: 'doctype{{> content}}',
        layout:
          '{{#> doctype}}{{#*inline "content"}}layout{{> subcontent}}{{/inline}}{{/doctype}}',
      })
      .toCompileTo('doctypelayoutsubcontent');
  end

  it 'GH-1089: should support failover content in multiple levels of inline partials' do
    expectTemplate('{{#> layout}}{{/layout}}')
      .withPartials({
        doctype: 'doctype{{> content}}',
        layout:
          '{{#> doctype}}{{#*inline "content"}}layout{{#> subcontent}}subcontent{{/subcontent}}{{/inline}}{{/doctype}}',
      })
      .toCompileTo('doctypelayoutsubcontent');
  end

  it 'GH-1099: should support greater than 3 nested levels of inline partials' do
    expectTemplate('{{#> layout}}Outer{{/layout}}')
      .withPartials({
        layout: '{{#> inner}}Inner{{/inner}}{{> @partial-block }}',
        inner: '',
      })
      .toCompileTo('Outer');
  end

  it 'GH-1135 : Context handling within each iteration' do
    expectTemplate(
      '{{#each array}}\n' +
        ' 1. IF: {{#if true}}{{../name}}-{{../../name}}-{{../../../name}}{{/if}}\n' +
        ' 2. MYIF: {{#myif true}}{{../name}}={{../../name}}={{../../../name}}{{/myif}}\n' +
        '{{/each}}'
    )
      .withInput({ array: [1], name: 'John' })
      .withHelpers({
        myif: lambda { |conditional, options|
          if conditional
            return options.fn(this);
          else
            return options.inverse(this);
          end
        },
      })
      .toCompileTo(' 1. IF: John--\n' + ' 2. MYIF: John==\n');
  end

  it 'GH-1186: Support block params for existing programs' do
    expectTemplate(
      '{{#*inline "test"}}{{> @partial-block }}{{/inline}}' +
        '{{#>test }}{{#each listOne as |item|}}{{ item }}{{/each}}{{/test}}' +
        '{{#>test }}{{#each listTwo as |item|}}{{ item }}{{/each}}{{/test}}'
    )
      .withInput({
        listOne: ['a'],
        listTwo: ['b'],
      })
      .withMessage('')
      .toCompileTo('ab');
  end

  it 'should allow hash with protected array names' do
    obj = { array: [1], name: 'John' };
    helpers = {
      helpa: lambda { |options|
        return options.hash[:length];
      },
    };

    shouldCompileTo('{{helpa length="foo"}}', [obj, helpers], 'foo');
  end

  it 'GH-1319: "unless" breaks when "each" value equals "null"' do
    expectTemplate(
      '{{#each list}}{{#unless ./prop}}parent={{../value}} {{/unless}}{{/each}}'
    )
      .withInput({
        value: 'parent',
        list: [null, 'a'],
      })
      .withMessage('')
      .toCompileTo('parent=parent parent=parent ');
  end

  it 'GH-1341: 4.0.7 release breaks {{#if @partial-block}} usage' do
    expectTemplate('template {{>partial}} template')
      .withPartials({
        partialWithBlock:
          '{{#if @partial-block}} block {{> @partial-block}} block {{/if}}',
        partial: '{{#> partialWithBlock}} partial {{/partialWithBlock}}',
      })
      .toCompileTo('template  block  partial  block  template');
  end

  describe 'GH-1561: 4.3.x should still work with precompiled templates from 4.0.0 <= x < 4.3.0' do
    it 'should compile and execute templates' do
      skip "Haparanda has no old precompiled templates to take into account"
      newHandlebarsInstance = Handlebars.create;

      registerTemplate(newHandlebarsInstance, compiledTemplateVersion7);
      newHandlebarsInstance.register_helper('loud', lambda { |value|
        return value.upcase;
      });
      result = newHandlebarsInstance.templates['test.hbs'].call({
        name: 'yehuda',
      })
      equals(result.trim, 'YEHUDA');
    end

    it 'should call "helperMissing" if a helper is missing' do
      skip "Haparanda has no old precompiled templates to take into account"
      newHandlebarsInstance = Handlebars.create;

      shouldThrow(
        lambda {
          registerTemplate(newHandlebarsInstance, compiledTemplateVersion7);
          newHandlebarsInstance.templates['test.hbs'].call({});
        },
        Handlebars.Exception,
        'Missing helper: "loud"'
      );
    end

    it 'should pass "options.lookupProperty" to "lookup"-helper, even with old templates' do
      skip "Haparanda has no old precompiled templates to take into account"
      newHandlebarsInstance = Handlebars.create;
      registerTemplate(
        newHandlebarsInstance,
        compiledTemplateVersion7_usingLookupHelper
      );

      newHandlebarsInstance.templates['test.hbs'].call({});

      expect(
        newHandlebarsInstance.templates['test.hbs'].call({
          property: 'a',
          test: { a: 'b' },
        })
      ).to.equal('b');
    end

    def registerTemplate(handlebars, compile_template) # rubocop:disable Naming/MethodName
      # rubocop:disable Layout/ArrayAlignment
      template = handlebars.template,
        templates = (handlebars.templates = handlebars.templates || {});
      templates['test.hbs'] = template.call(compile_template);
      # rubocop:enable Layout/ArrayAlignment
    end

    let(:compiledTemplateVersion7) do
      lambda {
        return {
          compiler: [7, '>= 4.0.0'],
          main: lambda { |container, depth0, helpers, _partials, data|
            return (
              container.escapeExpression(
                (
                  helpers.loud ||
                  (depth0 && depth0.loud) ||
                  helpers.helperMissing
                ).call(
                  depth0 != null ? depth0 : container.nullContext || {},
                  depth0 != null ? depth0.name : depth0,
                  { name: 'loud', hash: {}, data: data }
                )
              ) + '\n\n'
            );
          },
          useData: true,
        };
      }
    end

    let(:compiledTemplateVersion7_usingLookupHelper) do
      lambda {
        # This is the compiled version of "{{lookup test property}}"
        return {
          compiler: [7, '>= 4.0.0'],
          main: lambda { |container, depth0, helpers, _partials, data|
            return container.escapeExpression(
              helpers.lookup.call(
                depth0 != null ? depth0 : container.nullContext || {},
                depth0 != null ? depth0.test : depth0,
                depth0 != null ? depth0.property : depth0,
                {
                  name: 'lookup',
                  hash: {},
                  data: data,
                }
              )
            );
          },
          useData: true,
        };
      }
    end
  end

  it 'should allow hash with protected array names' do
    expectTemplate('{{helpa length="foo"}}')
      .withInput({ array: [1], name: 'John' })
      .withHelpers({
        helpa: lambda { |options|
          return options.hash[:length];
        },
      })
      .toCompileTo('foo');
  end

  describe 'GH-1598: Performance degradation for partials since v4.3.0' do
    let(:newHandlebarsInstance) { Haparanda::Compiler.new }

    after do
      sinon.restore;
    end

    it 'should only compile global partials once' do
      skip
      templateSpy = sinon.spy(newHandlebarsInstance, 'template');
      newHandlebarsInstance.register_partial({
        dude: 'I am a partial',
      })
      string = 'Dudes: {{> dude}} {{> dude}}';
      newHandlebarsInstance.compile(string).call; # This should compile template + partial once
      newHandlebarsInstance.compile(string).call; # This should only compile template
      equal(templateSpy.callCount, 3);
      sinon.restore;
    end
  end

  describe "GH-1639: TypeError: Cannot read property 'apply' of undefined\" when handlebars version > 4.6.0 (undocumented, deprecated usage)" do
    it 'should treat undefined helpers like non-existing helpers' do
      expectTemplate('{{foo}}')
        .withHelper('foo', undefined)
        .withInput({ foo: 'bar' })
        .toCompileTo('bar');
    end
  end
end
