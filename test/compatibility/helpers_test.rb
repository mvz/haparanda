# frozen_string_literal: true

require "test_helper"

# Based on spec/helpers.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/helpers.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'helpers' do
  it 'helper with complex lookup$' do
    expectTemplate('{{#goodbyes}}{{{link ../prefix}}}{{/goodbyes}}')
      .withInput({
        prefix: '/root',
        goodbyes: [{ text: 'Goodbye', url: 'goodbye' }],
      })
      .withHelper('link', lambda { |prefix|
        return (
          '<a href="' + prefix + '/' + this.url + '">' + this.text + '</a>'
        );
      })
      .toCompileTo('<a href="/root/goodbye">Goodbye</a>');
  end

  it 'helper for raw block gets raw content' do
    expectTemplate('{{{{raw}}}} {{test}} {{{{/raw}}}}')
      .withInput({ test: 'hello' })
      .withHelper('raw', lambda { |options|
        return options.fn;
      })
      .withMessage('raw block helper gets raw content')
      .toCompileTo(' {{test}} ');
  end

  it 'helper for raw block gets parameters' do
    expectTemplate('{{{{raw 1 2 3}}}} {{test}} {{{{/raw}}}}')
      .withInput({ test: 'hello' })
      .withHelper('raw', lambda { |a, b, c, options|
        return options.fn + a.to_s + b.to_s + c.to_s;
      })
      .withMessage('raw block helper gets raw content')
      .toCompileTo(' {{test}} 123');
  end

  describe 'raw block parsing (with identity helper-function)' do
    def runWithIdentityHelper(template, expected) # rubocop:disable Naming/MethodName
      expectTemplate(template)
        .withHelper('identity', lambda { |options|
          return options.fn;
        })
        .toCompileTo(expected);
    end

    it 'helper for nested raw block gets raw content' do
      runWithIdentityHelper(
        '{{{{identity}}}} {{{{b}}}} {{{{/b}}}} {{{{/identity}}}}',
        ' {{{{b}}}} {{{{/b}}}} '
      );
    end

    it 'helper for nested raw block works with empty content' do
      runWithIdentityHelper('{{{{identity}}}}{{{{/identity}}}}', '');
    end

    it 'helper for nested raw block works if nested raw blocks are broken' do
      skip 'deactivated'
      # This test was introduced in 4.4.4, but it was not the actual problem that lead to the patch release
      # The test is deactivated, because in 3.x this template cases an exception and it also does not work in 4.4.3
      # If anyone can make this template work without breaking everything else, then go for it,
      # but for now, this is just a known bug, that will be documented.
      runWithIdentityHelper(
        '{{{{identity}}}} {{{{a}}}} {{{{ {{{{/ }}}} }}}} {{{{/identity}}}}',
        ' {{{{a}}}} {{{{ {{{{/ }}}} }}}} '
      );
    end

    it 'helper for nested raw block closes after first matching close' do
      runWithIdentityHelper(
        '{{{{identity}}}}abc{{{{/identity}}}} {{{{identity}}}}abc{{{{/identity}}}}',
        'abc abc'
      );
    end

    it 'helper for nested raw block throw exception when with missing closing braces' do
      string = '{{{{a}}}} {{{{/a';
      expectTemplate(string).toThrow Haparanda::HandlebarsLexer::ScanError;
    end
  end

  it 'helper block with identical context' do
    expectTemplate('{{#goodbyes}}{{name}}{{/goodbyes}}')
      .withInput({ name: 'Alan' })
      .withHelper('goodbyes', lambda { |options|
        out = '';
        byes = ['Goodbye', 'goodbye', 'GOODBYE'];
        byes.length.times do |i|
          out += byes[i] + ' ' + options.fn(this) + '! ';
        end
        return out;
      })
      .toCompileTo('Goodbye Alan! goodbye Alan! GOODBYE Alan! ');
  end

  it 'helper block with complex lookup expression' do
    expectTemplate('{{#goodbyes}}{{../name}}{{/goodbyes}}')
      .withInput({ name: 'Alan' })
      .withHelper('goodbyes', lambda { |options|
        out = '';
        byes = ['Goodbye', 'goodbye', 'GOODBYE'];
        byes.length.times do |i|
          out += byes[i] + ' ' + options.fn({}) + '! ';
        end
        return out;
      })
      .toCompileTo('Goodbye Alan! goodbye Alan! GOODBYE Alan! ');
  end

  it 'helper with complex lookup and nested template' do
    expectTemplate(
      '{{#goodbyes}}{{#link ../prefix}}{{text}}{{/link}}{{/goodbyes}}'
    )
      .withInput({
        prefix: '/root',
        goodbyes: [{ text: 'Goodbye', url: 'goodbye' }],
      })
      .withHelper('link', lambda { |prefix, options|
        return (
          '<a href="' +
          prefix +
          '/' +
          this.url +
          '">' +
          options.fn(this) +
          '</a>'
        );
      })
      .toCompileTo('<a href="/root/goodbye">Goodbye</a>');
  end

  it 'helper with complex lookup and nested template in VM+Compiler' do
    expectTemplate(
      '{{#goodbyes}}{{#link ../prefix}}{{text}}{{/link}}{{/goodbyes}}'
    )
      .withInput({
        prefix: '/root',
        goodbyes: [{ text: 'Goodbye', url: 'goodbye' }],
      })
      .withHelper('link', lambda { |prefix, options|
        return (
          '<a href="' +
          prefix +
          '/' +
          this.url +
          '">' +
          options.fn(this) +
          '</a>'
        );
      })
      .toCompileTo('<a href="/root/goodbye">Goodbye</a>');
  end

  it 'helper returning undefined value' do
    expectTemplate(' {{nothere}}')
      .withHelpers({
        nothere: -> {},
      })
      .toCompileTo(' ');

    expectTemplate(' {{#nothere}}{{/nothere}}')
      .withHelpers({
        nothere: -> {},
      })
      .toCompileTo(' ');
  end

  it 'block helper' do
    expectTemplate('{{#goodbyes}}{{text}}! {{/goodbyes}}cruel {{world}}!')
      .withInput({ world: 'world' })
      .withHelper('goodbyes', lambda { |options|
        return options.fn({ text: 'GOODBYE' });
      })
      .withMessage('Block helper executed')
      .toCompileTo('GOODBYE! cruel world!');
  end

  it 'block helper staying in the same context' do
    expectTemplate('{{#form}}<p>{{name}}</p>{{/form}}')
      .withInput({ name: 'Yehuda' })
      .withHelper('form', lambda { |options|
        return '<form>' + options.fn(this) + '</form>';
      })
      .withMessage('Block helper executed with current context')
      .toCompileTo('<form><p>Yehuda</p></form>');
  end

  it 'block helper should have context in this' do
    link = lambda { |options|
      return '<a href="/people/' + this.id.to_s + '">' + options.fn(this) + '</a>';
    }

    expectTemplate(
      '<ul>{{#people}}<li>{{#link}}{{name}}{{/link}}</li>{{/people}}</ul>'
    )
      .withInput({
        people: [
          { name: 'Alan', id: 1 },
          { name: 'Yehuda', id: 2 },
        ],
      })
      .withHelper('link', link)
      .toCompileTo(
        '<ul><li><a href="/people/1">Alan</a></li><li><a href="/people/2">Yehuda</a></li></ul>'
      );
  end

  it 'block helper for undefined value' do
    expectTemplate("{{#empty}}shouldn't render{{/empty}}").toCompileTo('');
  end

  it 'block helper passing a new context' do
    expectTemplate('{{#form yehuda}}<p>{{name}}</p>{{/form}}')
      .withInput({ yehuda: { name: 'Yehuda' } })
      .withHelper('form', lambda { |context, options|
        return '<form>' + options.fn(context) + '</form>';
      })
      .withMessage('Context variable resolved')
      .toCompileTo('<form><p>Yehuda</p></form>');
  end

  it 'block helper passing a complex path context' do
    expectTemplate('{{#form yehuda/cat}}<p>{{name}}</p>{{/form}}')
      .withInput({ yehuda: { name: 'Yehuda', cat: { name: 'Harold' } } })
      .withHelper('form', lambda { |context, options|
        return '<form>' + options.fn(context) + '</form>';
      })
      .withMessage('Complex path variable resolved')
      .toCompileTo('<form><p>Harold</p></form>');
  end

  it 'nested block helpers' do
    expectTemplate(
      '{{#form yehuda}}<p>{{name}}</p>{{#link}}Hello{{/link}}{{/form}}'
    )
      .withInput({
        yehuda: { name: 'Yehuda' },
      })
      .withHelper('link', lambda { |options|
        return '<a href="' + this.name + '">' + options.fn(this) + '</a>';
      })
      .withHelper('form', lambda { |context, options|
        return '<form>' + options.fn(context) + '</form>';
      })
      .withMessage('Both blocks executed')
      .toCompileTo('<form><p>Yehuda</p><a href="Yehuda">Hello</a></form>');
  end

  it 'block helper inverted sections' do
    string = "{{#list people}}{{name}}{{^}}<em>Nobody's here</em>{{/list}}";
    list = lambda { |context, options|
      if context.length > 0
        out = '<ul>';
        context.length.times do |i|
          out += '<li>';
          out += options.fn(context[i]);
          out += '</li>';
        end
        out += '</ul>';
        return out;
      else
        return '<p>' + options.inverse(this) + '</p>';
      end
    }

    # the meaning here may be kind of hard to catch, but list.not is always called,
    # so we should see the output of both
    expectTemplate(string)
      .withInput({ people: [{ name: 'Alan' }, { name: 'Yehuda' }] })
      .withHelpers({ list: list })
      .withMessage('an inverse wrapper is passed in as a new context')
      .toCompileTo('<ul><li>Alan</li><li>Yehuda</li></ul>');

    expectTemplate(string)
      .withInput({ people: [] })
      .withHelpers({ list: list })
      .withMessage('an inverse wrapper can be optionally called')
      .toCompileTo("<p><em>Nobody's here</em></p>");

    expectTemplate('{{#list people}}Hello{{^}}{{message}}{{/list}}')
      .withInput({
        people: [],
        message: "Nobody's here",
      })
      .withHelpers({ list: list })
      .withMessage('the context of an inverse is the parent of the block')
      .toCompileTo('<p>Nobody&#x27;s here</p>');
  end

  it 'pathed lambas with parameters' do
    hash = {
      helper: lambda {
        return 'winning';
      },
    };
    hash[:hash] = hash;
    helpers = {
      './helper': lambda {
        return 'fail';
      },
    };

    expectTemplate('{{./helper 1}}')
      .withInput(hash)
      .withHelpers(helpers)
      .toCompileTo('winning');

    expectTemplate('{{hash/helper 1}}')
      .withInput(hash)
      .withHelpers(helpers)
      .toCompileTo('winning');
  end

  describe 'helpers hash' do
    it 'providing a helpers hash' do
      expectTemplate('Goodbye {{cruel}} {{world}}!')
        .withInput({ cruel: 'cruel' })
        .withHelpers({
          world: lambda {
            return 'world';
          },
        })
        .withMessage('helpers hash is available')
        .toCompileTo('Goodbye cruel world!');

      expectTemplate('Goodbye {{#iter}}{{cruel}} {{world}}{{/iter}}!')
        .withInput({ iter: [{ cruel: 'cruel' }] })
        .withHelpers({
          world: lambda {
            return 'world';
          },
        })
        .withMessage('helpers hash is available inside other blocks')
        .toCompileTo('Goodbye cruel world!');
    end

    it 'in cases of conflict, helpers win' do
      expectTemplate('{{{lookup}}}')
        .withInput({ lookup: 'Explicit' })
        .withHelpers({
          lookup: lambda {
            return 'helpers';
          },
        })
        .withMessage('helpers hash has precedence escaped expansion')
        .toCompileTo('helpers');

      expectTemplate('{{lookup}}')
        .withInput({ lookup: 'Explicit' })
        .withHelpers({
          lookup: lambda {
            return 'helpers';
          },
        })
        .withMessage('helpers hash has precedence simple expansion')
        .toCompileTo('helpers');
    end

    it 'the helpers hash is available is nested contexts' do
      expectTemplate('{{#outer}}{{#inner}}{{helper}}{{/inner}}{{/outer}}')
        .withInput({ outer: { inner: { unused: [] } } })
        .withHelpers({
          helper: lambda {
            return 'helper';
          },
        })
        .withMessage('helpers hash is available in nested contexts.')
        .toCompileTo('helper');
    end

    it 'the helper hash should augment the global hash' do
      handlebarsEnv.register_helper('test_helper') do
        return 'found it!';
      end

      expectTemplate(
        '{{test_helper}} {{#if cruel}}Goodbye {{cruel}} {{world}}!{{/if}}'
      )
        .withInput({ cruel: 'cruel' })
        .withHelpers({
          world: lambda {
            return 'world!';
          },
        })
        .toCompileTo('found it! Goodbye cruel world!!');
    end
  end

  describe 'registration' do
    it 'unregisters' do
      # handlebarsEnv.helpers = {};

      handlebarsEnv.register_helper('foo') do
        return 'fail';
      end
      handlebarsEnv.unregister_helper('foo');
      equals(handlebarsEnv.get_helper('foo'), nil);
    end

    it 'allows multiple globals' do
      skip "we only allow calling this method with a name and block"
      var helpers = handlebarsEnv.helpers;
      handlebarsEnv.helpers = {};

      handlebarsEnv.registerHelper({
        if: helpers['if'],
        world: lambda {
          return 'world!';
        },
        testHelper: lambda {
          return 'found it!';
        },
      });

      expectTemplate(
        '{{testHelper}} {{#if cruel}}Goodbye {{cruel}} {{world}}!{{/if}}'
      )
        .withInput({ cruel: 'cruel' })
        .toCompileTo('found it! Goodbye cruel world!!');
    end

    it 'fails with multiple and args' do
      skip "we only allow calling this method with a name and block"
      shouldThrow(
        lambda {
          handlebarsEnv.registerHelper(
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
        'Arg not supported with multiple helpers'
      );
    end
  end

  it 'decimal number literals work' do
    expectTemplate('Message: {{hello -1.2 1.2}}')
      .withHelper('hello', lambda { |times, times2|
        if times.class != Float
          times = 'NaN';
        end
        if times2.class != Float
          times2 = 'NaN';
        end
        return 'Hello ' + times.to_s + ' ' + times2.to_s + ' times';
      })
      .withMessage('template with a negative integer literal')
      .toCompileTo('Message: Hello -1.2 1.2 times');
  end

  it 'negative number literals work' do
    expectTemplate('Message: {{hello -12}}')
      .withHelper('hello', lambda { |times|
        if times.class != Integer
          times = 'NaN';
        end
        return 'Hello ' + times.to_s + ' times';
      })
      .withMessage('template with a negative integer literal')
      .toCompileTo('Message: Hello -12 times');
  end

  describe 'String literal parameters' do
    it 'simple literals work' do
      expectTemplate('Message: {{hello "world" 12 true false}}')
        .withHelper('hello', lambda { |param, times, bool1, bool2|
          if times.class != Integer
            times = 'NaN';
          end
          if bool1.class != TrueClass
            bool1 = 'NaB';
          end
          if bool2.class != FalseClass
            bool2 = 'NaB';
          end
          return (
            'Hello ' + param.to_s + ' ' + times.to_s + ' times: ' + bool1.to_s + ' ' + bool2.to_s
          );
        })
        .withMessage('template with a simple String literal')
        .toCompileTo('Message: Hello world 12 times: true false');
    end

    it 'using a quote in the middle of a parameter raises an error' do
      expectTemplate('Message: {{hello wo"rld"}}').toThrow(Racc::ParseError);
    end

    it 'escaping a String is possible' do
      expectTemplate('Message: {{{hello "\\"world\\""}}}')
        .withHelper('hello', lambda { |param|
          return 'Hello ' + param;
        })
        .withMessage('template with an escaped String literal')
        .toCompileTo('Message: Hello "world"');
    end

    it "it works with ' marks" do
      expectTemplate('Message: {{{hello "Alan\'s world"}}}')
        .withHelper('hello', lambda { |param|
          return 'Hello ' + param;
        })
        .withMessage("template with a ' mark")
        .toCompileTo("Message: Hello Alan's world");
    end
  end

  it 'negative number literals work' do
    expectTemplate('Message: {{hello -12}}')
      .withHelper('hello', lambda { |times|
        if times.class != Integer
          times = 'NaN';
        end
        return 'Hello ' + times.to_s + ' times';
      })
      .withMessage('template with a negative integer literal')
      .toCompileTo('Message: Hello -12 times');
  end

  describe 'multiple parameters' do
    it 'simple multi-params work' do
      expectTemplate('Message: {{goodbye cruel world}}')
        .withInput({ cruel: 'cruel', world: 'world' })
        .withHelper('goodbye', lambda { |cruel, world|
          return 'Goodbye ' + cruel + ' ' + world;
        })
        .withMessage('regular helpers with multiple params')
        .toCompileTo('Message: Goodbye cruel world');
    end

    it 'block multi-params work' do
      expectTemplate(
        'Message: {{#goodbye cruel world}}{{greeting}} {{adj}} {{noun}}{{/goodbye}}'
      )
        .withInput({ cruel: 'cruel', world: 'world' })
        .withHelper('goodbye', lambda { |cruel, world, options|
          return options.fn({ greeting: 'Goodbye', adj: cruel, noun: world });
        })
        .withMessage('block helpers with multiple params')
        .toCompileTo('Message: Goodbye cruel world');
    end
  end

  describe 'hash' do
    it 'helpers can take an optional hash' do
      expectTemplate('{{goodbye cruel="CRUEL" world="WORLD" times=12}}')
        .withHelper('goodbye', lambda { |options|
          return (
            'GOODBYE ' +
            options.hash[:cruel] +
            ' ' +
            options.hash[:world] +
            ' ' +
            options.hash[:times].to_s +
            ' TIMES'
          );
        })
        .withMessage('Helper output hash')
        .toCompileTo('GOODBYE CRUEL WORLD 12 TIMES');
    end

    it 'helpers can take an optional hash with booleans' do
      goodbye = lambda { |options|
        if options.hash[:print] == true
          return 'GOODBYE ' + options.hash[:cruel] + ' ' + options.hash[:world];
        elsif options.hash[:print] == false
          return 'NOT PRINTING';
        else
          return 'THIS SHOULD NOT HAPPEN';
        end
      }

      expectTemplate('{{goodbye cruel="CRUEL" world="WORLD" print=true}}')
        .withHelper('goodbye', goodbye)
        .withMessage('Helper output hash')
        .toCompileTo('GOODBYE CRUEL WORLD');

      expectTemplate('{{goodbye cruel="CRUEL" world="WORLD" print=false}}')
        .withHelper('goodbye', goodbye)
        .withMessage('Boolean helper parameter honored')
        .toCompileTo('NOT PRINTING');
    end

    it 'block helpers can take an optional hash' do
      expectTemplate('{{#goodbye cruel="CRUEL" times=12}}world{{/goodbye}}')
        .withHelper('goodbye', lambda { |options|
          return (
            'GOODBYE ' +
            options.hash[:cruel] +
            ' ' +
            options.fn(this) +
            ' ' +
            options.hash[:times].to_s +
            ' TIMES'
          );
        })
        .withMessage('Hash parameters output')
        .toCompileTo('GOODBYE CRUEL world 12 TIMES');
    end

    it 'block helpers can take an optional hash with single quoted stings' do
      expectTemplate('{{#goodbye cruel=\'CRUEL\' times=12}}world{{/goodbye}}')
        .withHelper('goodbye', lambda { |options|
          return (
            'GOODBYE ' +
            options.hash[:cruel] +
            ' ' +
            options.fn(this) +
            ' ' +
            options.hash[:times].to_s +
            ' TIMES'
          );
        })
        .withMessage('Hash parameters output')
        .toCompileTo('GOODBYE CRUEL world 12 TIMES');
    end

    it 'block helpers can take an optional hash with booleans' do
      goodbye = lambda { |options|
        if options.hash[:print] == true
          return 'GOODBYE ' + options.hash[:cruel] + ' ' + options.fn(this);
        elsif options.hash[:print] == false
          return 'NOT PRINTING';
        else
          return 'THIS SHOULD NOT HAPPEN';
        end
      }

      expectTemplate('{{#goodbye cruel="CRUEL" print=true}}world{{/goodbye}}')
        .withHelper('goodbye', goodbye)
        .withMessage('Boolean hash parameter honored')
        .toCompileTo('GOODBYE CRUEL world');

      expectTemplate('{{#goodbye cruel="CRUEL" print=false}}world{{/goodbye}}')
        .withHelper('goodbye', goodbye)
        .withMessage('Boolean hash parameter honored')
        .toCompileTo('NOT PRINTING');
    end
  end

  describe 'helperMissing' do
    it 'if a context is not found, helperMissing is used' do
      expectTemplate('{{hello}} {{link_to world}}').toThrow(
        RuntimeError,
        /Missing helper: "link_to"/
      );
    end

    it 'if a context is not found, custom helperMissing is used' do
      expectTemplate('{{hello}} {{link_to world}}')
        .withInput({ hello: 'Hello', world: 'world' })
        .withHelper('helperMissing', lambda { |mesg, options|
          if options.name == "link_to"
            return Haparanda::HandlebarsProcessor::SafeString.new('<a>' + mesg + '</a>');
          end
        })
        .toCompileTo('Hello <a>world</a>');
    end

    it 'if a value is not found, custom helperMissing is used' do
      expectTemplate('{{hello}} {{link_to}}')
        .withInput({ hello: 'Hello', world: 'world' })
        .withHelper('helperMissing', lambda { |options|
          if options.name == "link_to"
            return Haparanda::HandlebarsProcessor::SafeString.new('<a>winning</a>');
          end
        })
        .toCompileTo('Hello <a>winning</a>');
    end
  end

  describe 'knownHelpers' do
    it 'Known helper should render helper' do
      expectTemplate('{{hello}}')
        .withCompileOptions({
          knownHelpers: { hello: true },
        })
        .withHelper('hello', lambda {
          return 'foo';
        })
        .toCompileTo('foo');
    end

    it 'Unknown helper in knownHelpers only mode should be passed as undefined' do
      expectTemplate('{{typeof hello}}')
        .withCompileOptions({
          knownHelpers: { typeof: true },
          knownHelpersOnly: true,
        })
        .withHelper('typeof', lambda { |arg|
          return arg.class;
        })
        .withHelper('hello', lambda {
          return 'foo';
        })
        .toCompileTo('NilClass');
    end

    it 'Builtin helpers available in knownHelpers only mode' do
      expectTemplate('{{#unless foo}}bar{{/unless}}')
        .withCompileOptions({
          knownHelpersOnly: true,
        })
        .toCompileTo('bar');
    end

    it 'Field lookup works in knownHelpers only mode' do
      expectTemplate('{{foo}}')
        .withCompileOptions({
          knownHelpersOnly: true,
        })
        .withInput({ foo: 'bar' })
        .toCompileTo('bar');
    end

    it 'Conditional blocks work in knownHelpers only mode' do
      expectTemplate('{{#foo}}bar{{/foo}}')
        .withCompileOptions({
          knownHelpersOnly: true,
        })
        .withInput({ foo: 'baz' })
        .toCompileTo('bar');
    end

    it 'Invert blocks work in knownHelpers only mode' do
      expectTemplate('{{^foo}}bar{{/foo}}')
        .withCompileOptions({
          knownHelpersOnly: true,
        })
        .withInput({ foo: false })
        .toCompileTo('bar');
    end

    it 'Functions are bound to the context in knownHelpers only mode' do
      expectTemplate('{{foo}}')
        .withCompileOptions({
          knownHelpersOnly: true,
        })
        .withInput({
          foo: lambda {
            return this.bar;
          },
          bar: 'bar',
        })
        .toCompileTo('bar');
    end

    it 'Unknown helper call in knownHelpers only mode should throw' do
      expectTemplate('{{typeof hello}}')
        .withCompileOptions({ knownHelpersOnly: true })
        .toThrow(RuntimeError);
    end
  end

  describe 'blockHelperMissing' do
    it 'lambdas are resolved by blockHelperMissing, not handlebars proper' do
      expectTemplate('{{#truthy}}yep{{/truthy}}')
        .withInput({
          truthy: lambda {
            return true;
          },
        })
        .toCompileTo('yep');
    end

    it 'lambdas resolved by blockHelperMissing are bound to the context' do
      expectTemplate('{{#truthy}}yep{{/truthy}}')
        .withInput({
          truthy: lambda {
            return this.truthiness;
          },
          truthiness: lambda {
            return false;
          },
        })
        .toCompileTo('');
    end
  end

  describe 'name field' do
    helpers = {
      blockHelperMissing: lambda { |*arguments|
        return 'missing: ' + arguments[arguments.length - 1].name.to_s;
      },
      helperMissing: lambda { |*arguments|
        return 'helper missing: ' + arguments[arguments.length - 1].name.to_s;
      },
      helper: lambda { |*arguments|
        return 'ran: ' + arguments[arguments.length - 1].name.to_s;
      },
    };

    it 'should include in ambiguous mustache calls' do
      expectTemplate('{{helper}}')
        .withHelpers(helpers)
        .toCompileTo('ran: helper');
    end

    it 'should include in helper mustache calls' do
      expectTemplate('{{helper 1}}')
        .withHelpers(helpers)
        .toCompileTo('ran: helper');
    end

    it 'should include in ambiguous block calls' do
      expectTemplate('{{#helper}}{{/helper}}')
        .withHelpers(helpers)
        .toCompileTo('ran: helper');
    end

    it 'should include in simple block calls' do
      expectTemplate('{{#./helper}}{{/./helper}}')
        .withHelpers(helpers)
        .toCompileTo('missing: ./helper');
    end

    it 'should include in helper block calls' do
      expectTemplate('{{#helper 1}}{{/helper}}')
        .withHelpers(helpers)
        .toCompileTo('ran: helper');
    end

    it 'should include in known helper calls' do
      expectTemplate('{{helper}}')
        .withCompileOptions({
          knownHelpers: { helper: true },
          knownHelpersOnly: true,
        })
        .withHelpers(helpers)
        .toCompileTo('ran: helper');
    end

    it 'should include full id' do
      expectTemplate('{{#foo.helper}}{{/foo.helper}}')
        .withInput({ foo: {} })
        .withHelpers(helpers)
        .toCompileTo('missing: foo.helper');
    end

    it 'should include full id if a hash is passed' do
      expectTemplate('{{#foo.helper bar=baz}}{{/foo.helper}}')
        .withInput({ foo: {} })
        .withHelpers(helpers)
        .toCompileTo('helper missing: foo.helper');
    end
  end

  describe 'name conflicts' do
    it 'helpers take precedence over same-named context properties' do
      expectTemplate('{{goodbye}} {{cruel world}}')
        .withHelper('goodbye', lambda {
          return this.goodbye.upcase;
        })
        .withHelper('cruel', lambda { |world|
          return 'cruel ' + world.upcase;
        })
        .withInput({
          goodbye: 'goodbye',
          world: 'world',
        })
        .withMessage('Helper executed')
        .toCompileTo('GOODBYE cruel WORLD');
    end

    it 'helpers take precedence over same-named context properties$' do
      expectTemplate('{{#goodbye}} {{cruel world}}{{/goodbye}}')
        .withHelper('goodbye', lambda { |options|
          return this.goodbye.upcase + options.fn(this);
        })
        .withHelper('cruel', lambda { |world|
          return 'cruel ' + world.upcase;
        })
        .withInput({
          goodbye: 'goodbye',
          world: 'world',
        })
        .withMessage('Helper executed')
        .toCompileTo('GOODBYE cruel WORLD');
    end

    it 'Scoped names take precedence over helpers' do
      expectTemplate('{{this.goodbye}} {{cruel world}} {{cruel this.goodbye}}')
        .withHelper('goodbye', lambda {
          return this.goodbye.upcase;
        })
        .withHelper('cruel', lambda { |world|
          return 'cruel ' + world.upcase;
        })
        .withInput({
          goodbye: 'goodbye',
          world: 'world',
        })
        .withMessage('Helper not executed')
        .toCompileTo('goodbye cruel WORLD cruel GOODBYE');
    end

    it 'Scoped names take precedence over block helpers' do
      expectTemplate(
        '{{#goodbye}} {{cruel world}}{{/goodbye}} {{this.goodbye}}'
      )
        .withHelper('goodbye', lambda { |options|
          return this.goodbye.upcase + options.fn(this);
        })
        .withHelper('cruel', lambda { |world|
          return 'cruel ' + world.upcase;
        })
        .withInput({
          goodbye: 'goodbye',
          world: 'world',
        })
        .withMessage('Helper executed')
        .toCompileTo('GOODBYE cruel WORLD goodbye');
    end
  end

  describe 'block params' do
    it 'should take precedence over context values' do
      test = self
      expectTemplate('{{#goodbyes as |value|}}{{value}}{{/goodbyes}}{{value}}')
        .withInput({ value: 'foo' })
        .withHelper('goodbyes', lambda { |options|
          test.equals(options.block_params, 1);
          return options.fn({ value: 'bar' }, { block_params: [1, 2] });
        })
        .toCompileTo('1foo');
    end

    it 'should take precedence over helper values' do
      test = self
      expectTemplate('{{#goodbyes as |value|}}{{value}}{{/goodbyes}}{{value}}')
        .withHelper('value', lambda {
          return 'foo';
        })
        .withHelper('goodbyes', lambda { |options|
          test.equals(options.block_params, 1);
          return options.fn({}, { block_params: [1, 2] });
        })
        .toCompileTo('1foo');
    end

    it 'should not take precedence over pathed values' do
      test = self
      expectTemplate(
        '{{#goodbyes as |value|}}{{./value}}{{/goodbyes}}{{value}}'
      )
        .withInput({ value: 'bar' })
        .withHelper('value', lambda {
          return 'foo';
        })
        .withHelper('goodbyes', lambda { |options|
          test.equals(options.block_params, 1);
          return options.fn(this, { block_params: [1, 2] });
        })
        .toCompileTo('barfoo');
    end

    it 'should take precedence over parent block params' do
      value = 0;
      undefined = nil
      expectTemplate(
        '{{#goodbyes as |value|}}{{#goodbyes}}{{value}}{{#goodbyes as |value|}}{{value}}{{/goodbyes}}{{/goodbyes}}{{/goodbyes}}{{value}}'
      )
        .withInput({ value: 'foo' })
        .withHelper('goodbyes', lambda { |options|
          return options.fn(
            { value: 'bar' },
            {
              block_params:
                options.block_params == 1 ? [value += 1, value += 1] : undefined,
            }
          );
        })
        .toCompileTo('13foo');
    end

    it 'should allow block params on chained helpers' do
      test = self
      expectTemplate(
        '{{#if bar}}{{else goodbyes as |value|}}{{value}}{{/if}}{{value}}'
      )
        .withInput({ value: 'foo' })
        .withHelper('goodbyes', lambda { |options|
          test.equals(options.block_params, 1);
          return options.fn({ value: 'bar' }, { block_params: [1, 2] });
        })
        .toCompileTo('1foo');
    end
  end

  describe 'built-in helpers malformed arguments ' do
    it 'if helper - too few arguments' do
      expectTemplate('{{#if}}{{/if}}').toThrow(
        /#if requires exactly one argument/
      );
    end

    it 'if helper - too many arguments, string' do
      expectTemplate('{{#if test "string"}}{{/if}}').toThrow(
        /#if requires exactly one argument/
      );
    end

    it 'if helper - too many arguments, undefined' do
      expectTemplate('{{#if test undefined}}{{/if}}').toThrow(
        /#if requires exactly one argument/
      );
    end

    it 'if helper - too many arguments, null' do
      expectTemplate('{{#if test null}}{{/if}}').toThrow(
        /#if requires exactly one argument/
      );
    end

    it 'unless helper - too few arguments' do
      expectTemplate('{{#unless}}{{/unless}}').toThrow(
        /#unless requires exactly one argument/
      );
    end

    it 'unless helper - too many arguments' do
      expectTemplate('{{#unless test null}}{{/unless}}').toThrow(
        /#unless requires exactly one argument/
      );
    end

    it 'with helper - too few arguments' do
      expectTemplate('{{#with}}{{/with}}').toThrow(
        /#with requires exactly one argument/
      );
    end

    it 'with helper - too many arguments' do
      expectTemplate('{{#with test "string"}}{{/with}}').toThrow(
        /#with requires exactly one argument/
      );
    end
  end

  describe 'the lookupProperty-option' do
    it 'should be passed to custom helpers' do
      skip
      expectTemplate('{{testHelper}}')
        .withHelper('testHelper', lambda { |options|
          return options.lookupProperty(this, 'testProperty');
        })
        .withInput({ testProperty: 'abc' })
        .toCompileTo('abc');
    end
  end
end
