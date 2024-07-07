# frozen_string_literal: true

require "test_helper"

# Based on spec/builtins.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.

# rubocop:disable Style/StringLiterals
describe 'builtin helpers' do
  # rubocop:disable Layout/FirstHashElementIndentation
  # rubocop:disable Layout/FirstArrayElementIndentation
  # rubocop:disable Layout/LineLength
  # rubocop:disable Style/NegatedIf
  # rubocop:disable Style/RedundantReturn
  # rubocop:disable Style/Semicolon
  # rubocop:disable Style/TrailingCommaInArrayLiteral
  # rubocop:disable Style/TrailingCommaInHashLiteral
  # rubocop:disable Style/WordArray
  describe '#if' do
    it 'if' do
      string = '{{#if goodbye}}GOODBYE {{/if}}cruel {{world}}!';

      expectTemplate(string)
        .withInput({
          goodbye: true,
          world: 'world',
        })
        .withMessage('if with boolean argument shows the contents when true')
        .toCompileTo('GOODBYE cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: 'dummy',
          world: 'world',
        })
        .withMessage('if with string argument shows the contents')
        .toCompileTo('GOODBYE cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: false,
          world: 'world',
        })
        .withMessage(
          'if with boolean argument does not show the contents when false'
        )
        .toCompileTo('cruel world!');

      expectTemplate(string)
        .withInput({ world: 'world' })
        .withMessage('if with undefined does not show the contents')
        .toCompileTo('cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: ['foo'],
          world: 'world',
        })
        .withMessage('if with non-empty array shows the contents')
        .toCompileTo('GOODBYE cruel world!');

      skip "we only consider falsy Ruby values as false"
      expectTemplate(string)
        .withInput({
          goodbye: [],
          world: 'world',
        })
        .withMessage('if with empty array does not show the contents')
        .toCompileTo('cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: 0,
          world: 'world',
        })
        .withMessage('if with zero does not show the contents')
        .toCompileTo('cruel world!');

      expectTemplate(
        '{{#if goodbye includeZero=true}}GOODBYE {{/if}}cruel {{world}}!'
      )
        .withInput({
          goodbye: 0,
          world: 'world',
        })
        .withMessage('if with zero does not show the contents')
        .toCompileTo('GOODBYE cruel world!');
    end

    it 'if with function argument' do
      skip "functions are not supported"
      var string = '{{#if goodbye}}GOODBYE {{/if}}cruel {{world}}!';

      expectTemplate(string)
        .withInput({
          goodbye: lambda {
            return true;
          },
          world: 'world',
        })
        .withMessage(
          'if with function shows the contents when function returns true'
        )
        .toCompileTo('GOODBYE cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: lambda {
            return this.world;
          },
          world: 'world',
        })
        .withMessage(
          'if with function shows the contents when function returns string'
        )
        .toCompileTo('GOODBYE cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: lambda {
            return false;
          },
          world: 'world',
        })
        .withMessage(
          'if with function does not show the contents when returns false'
        )
        .toCompileTo('cruel world!');

      expectTemplate(string)
        .withInput({
          goodbye: lambda {
            return this.foo;
          },
          world: 'world',
        })
        .withMessage(
          'if with function does not show the contents when returns undefined'
        )
        .toCompileTo('cruel world!');
    end

    it 'should not change the depth list' do
      skip
      expectTemplate(
        '{{#with foo}}{{#if goodbye}}GOODBYE cruel {{../world}}!{{/if}}{{/with}}'
      )
        .withInput({
          foo: { goodbye: true },
          world: 'world',
        })
        .toCompileTo('GOODBYE cruel world!');
    end
  end

  describe '#with' do
    it 'with' do
      expectTemplate('{{#with person}}{{first}} {{last}}{{/with}}')
        .withInput({
          person: {
            first: 'Alan',
            last: 'Johnson',
          },
        })
        .toCompileTo('Alan Johnson');
    end

    it 'with with function argument' do
      skip "functions are not supported"
      expectTemplate('{{#with person}}{{first}} {{last}}{{/with}}')
        .withInput({
          person: lambda {
            return {
              first: 'Alan',
              last: 'Johnson',
            };
          },
        })
        .toCompileTo('Alan Johnson');
    end

    it 'with with else' do
      expectTemplate(
        '{{#with person}}Person is present{{else}}Person is not present{{/with}}'
      ).toCompileTo('Person is not present');
    end

    it 'with provides block parameter' do
      skip
      expectTemplate('{{#with person as |foo|}}{{foo.first}} {{last}}{{/with}}')
        .withInput({
          person: {
            first: 'Alan',
            last: 'Johnson',
          },
        })
        .toCompileTo('Alan Johnson');
    end

    it 'works when data is disabled' do
      skip
      expectTemplate('{{#with person as |foo|}}{{foo.first}} {{last}}{{/with}}')
        .withInput({ person: { first: 'Alan', last: 'Johnson' } })
        .withCompileOptions({ data: false })
        .toCompileTo('Alan Johnson');
    end
  end

  describe '#each' do
    before do
      # handlebarsEnv.registerHelper('detectDataInsideEach', ->(options) {
      #   return options.data && options.data.exclaim;
      # });
    end

    it 'each' do
      skip
      var string = '{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!';

      expectTemplate(string)
        .withInput({
          goodbyes: [
            { text: 'goodbye' },
            { text: 'Goodbye' },
            { text: 'GOODBYE' },
          ],
          world: 'world',
        })
        .withMessage(
          'each with array argument iterates over the contents when not empty'
        )
        .toCompileTo('goodbye! Goodbye! GOODBYE! cruel world!');

      expectTemplate(string)
        .withInput({
          goodbyes: [],
          world: 'world',
        })
        .withMessage('each with array argument ignores the contents when empty')
        .toCompileTo('cruel world!');
    end

    it 'each without data' do
      skip
      expectTemplate('{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!')
        .withInput({
          goodbyes: [
            { text: 'goodbye' },
            { text: 'Goodbye' },
            { text: 'GOODBYE' },
          ],
          world: 'world',
        })
        .withRuntimeOptions({ data: false })
        .withCompileOptions({ data: false })
        .toCompileTo('goodbye! Goodbye! GOODBYE! cruel world!');

      expectTemplate('{{#each .}}{{.}}{{/each}}')
        .withInput({ goodbyes: 'cruel', world: 'world' })
        .withRuntimeOptions({ data: false })
        .withCompileOptions({ data: false })
        .toCompileTo('cruelworld');
    end

    it 'each without context' do
      skip
      expectTemplate('{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!')
        .withInput(undefined)
        .toCompileTo('cruel !');
    end

    it 'each with an object and @key' do
      skip
      var string =
            '{{#each goodbyes}}{{@key}}. {{text}}! {{/each}}cruel {{world}}!';

      function Clazz() {
        this['<b>#1</b>'] = { text: 'goodbye' };
        this[2] = { text: 'GOODBYE' };
      }
      Clazz.prototype.foo = 'fail';
      var hash = { goodbyes: Clazz.new, world: 'world' };

      # Object property iteration order is undefined according to ECMA spec,
      # so we need to check both possible orders
      # @see http://stackoverflow.com/questions/280713/elements-order-in-a-for-in-loop
      var actual = compileWithPartials(string, hash);
      var expected1 =
            '&lt;b&gt;#1&lt;/b&gt;. goodbye! 2. GOODBYE! cruel world!';
      var expected2 =
            '2. GOODBYE! &lt;b&gt;#1&lt;/b&gt;. goodbye! cruel world!';

      equals(
        actual === expected1 || actual === expected2,
        true,
        'each with object argument iterates over the contents when not empty'
      );

      expectTemplate(string)
        .withInput({
          goodbyes: {},
          world: 'world',
        })
        .toCompileTo('cruel world!');
    end

    it 'each with @index' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{@index}}. {{text}}! {{/each}}cruel {{world}}!'
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

    it 'each with nested @index' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{@index}}. {{text}}! {{#each ../goodbyes}}{{@index}} {{/each}}After {{@index}} {{/each}}{{@index}}cruel {{world}}!'
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
        .toCompileTo(
          '0. goodbye! 0 1 2 After 0 1. Goodbye! 0 1 2 After 1 2. GOODBYE! 0 1 2 After 2 cruel world!'
        );
    end

    it 'each with block params' do
      skip
      expectTemplate(
        '{{#each goodbyes as |value index|}}{{index}}. {{value.text}}! {{#each ../goodbyes as |childValue childIndex|}} {{index}} {{childIndex}}{{/each}} After {{index}} {{/each}}{{index}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: [{ text: 'goodbye' }, { text: 'Goodbye' }],
          world: 'world',
        })
        .toCompileTo(
          '0. goodbye!  0 0 0 1 After 0 1. Goodbye!  1 0 1 1 After 1 cruel world!'
        );
    end

    it 'each with block params and strict compilation' do
      skip
      expectTemplate(
        '{{#each goodbyes as |value index|}}{{index}}. {{value.text}}!{{/each}}'
      )
        .withCompileOptions({ strict: true })
        .withInput({ goodbyes: [{ text: 'goodbye' }, { text: 'Goodbye' }] })
        .toCompileTo('0. goodbye!1. Goodbye!');
    end

    it 'each object with @index' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{@index}}. {{text}}! {{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: {
            a: { text: 'goodbye' },
            b: { text: 'Goodbye' },
            c: { text: 'GOODBYE' },
          },
          world: 'world',
        })
        .withMessage('The @index variable is used')
        .toCompileTo('0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!');
    end

    it 'each with @first' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{#if @first}}{{text}}! {{/if}}{{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: [
            { text: 'goodbye' },
            { text: 'Goodbye' },
            { text: 'GOODBYE' },
          ],
          world: 'world',
        })
        .withMessage('The @first variable is used')
        .toCompileTo('goodbye! cruel world!');
    end

    it 'each with nested @first' do
      skip
      expectTemplate(
        '{{#each goodbyes}}({{#if @first}}{{text}}! {{/if}}{{#each ../goodbyes}}{{#if @first}}{{text}}!{{/if}}{{/each}}{{#if @first}} {{text}}!{{/if}}) {{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: [
            { text: 'goodbye' },
            { text: 'Goodbye' },
            { text: 'GOODBYE' },
          ],
          world: 'world',
        })
        .withMessage('The @first variable is used')
        .toCompileTo(
          '(goodbye! goodbye! goodbye!) (goodbye!) (goodbye!) cruel world!'
        );
    end

    it 'each object with @first' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{#if @first}}{{text}}! {{/if}}{{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: { foo: { text: 'goodbye' }, bar: { text: 'Goodbye' } },
          world: 'world',
        })
        .withMessage('The @first variable is used')
        .toCompileTo('goodbye! cruel world!');
    end

    it 'each with @last' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{#if @last}}{{text}}! {{/if}}{{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: [
            { text: 'goodbye' },
            { text: 'Goodbye' },
            { text: 'GOODBYE' },
          ],
          world: 'world',
        })
        .withMessage('The @last variable is used')
        .toCompileTo('GOODBYE! cruel world!');
    end

    it 'each object with @last' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{#if @last}}{{text}}! {{/if}}{{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: { foo: { text: 'goodbye' }, bar: { text: 'Goodbye' } },
          world: 'world',
        })
        .withMessage('The @last variable is used')
        .toCompileTo('Goodbye! cruel world!');
    end

    it 'each with nested @last' do
      skip
      expectTemplate(
        '{{#each goodbyes}}({{#if @last}}{{text}}! {{/if}}{{#each ../goodbyes}}{{#if @last}}{{text}}!{{/if}}{{/each}}{{#if @last}} {{text}}!{{/if}}) {{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: [
            { text: 'goodbye' },
            { text: 'Goodbye' },
            { text: 'GOODBYE' },
          ],
          world: 'world',
        })
        .withMessage('The @last variable is used')
        .toCompileTo(
          '(GOODBYE!) (GOODBYE!) (GOODBYE! GOODBYE! GOODBYE!) cruel world!'
        );
    end

    it 'each with function argument' do
      skip "functions are not supported"
      var string = '{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!';

      expectTemplate(string)
        .withInput({
          goodbyes: lambda {
            return [
              { text: 'goodbye' },
              { text: 'Goodbye' },
              { text: 'GOODBYE' },
            ];
          },
          world: 'world',
        })
        .withMessage(
          'each with array function argument iterates over the contents when not empty'
        )
        .toCompileTo('goodbye! Goodbye! GOODBYE! cruel world!');

      expectTemplate(string)
        .withInput({
          goodbyes: [],
          world: 'world',
        })
        .withMessage(
          'each with array function argument ignores the contents when empty'
        )
        .toCompileTo('cruel world!');
    end

    it 'each object when last key is an empty string' do
      skip
      expectTemplate(
        '{{#each goodbyes}}{{@index}}. {{text}}! {{/each}}cruel {{world}}!'
      )
        .withInput({
          goodbyes: {
            a: { text: 'goodbye' },
            b: { text: 'Goodbye' },
            '': { text: 'GOODBYE' },
          },
          world: 'world',
        })
        .withMessage('Empty string key is not skipped')
        .toCompileTo('0. goodbye! 1. Goodbye! 2. GOODBYE! cruel world!');
    end

    it 'data passed to helpers' do
      skip
      expectTemplate(
        '{{#each letters}}{{this}}{{detectDataInsideEach}}{{/each}}'
      )
        .withInput({ letters: ['a', 'b', 'c'] })
        .withMessage('should output data')
        .withRuntimeOptions({
          data: {
            exclaim: '!',
          },
        })
        .toCompileTo('a!b!c!');
    end

    it 'each on implicit context' do
      skip
      expectTemplate('{{#each}}{{text}}! {{/each}}cruel world!').toThrow(
        handlebarsEnv.Exception,
        'Must pass iterator to #each'
      );
    end

    it 'each on Map' do
      skip
      var map = Map.new([
        [1, 'one'],
        [2, 'two'],
        [3, 'three'],
      ]);

      expectTemplate('{{#each map}}{{@key}}(i{{@index}}) {{.}} {{/each}}')
        .withInput({ map: map })
        .toCompileTo('1(i0) one 2(i1) two 3(i2) three ');

      expectTemplate('{{#each map}}{{#if @first}}{{.}}{{/if}}{{/each}}')
        .withInput({ map: map })
        .toCompileTo('one');

      expectTemplate('{{#each map}}{{#if @last}}{{.}}{{/if}}{{/each}}')
        .withInput({ map: map })
        .toCompileTo('three');

      expectTemplate('{{#each map}}{{.}}{{/each}}not-in-each')
        .withInput({ map: Map.new })
        .toCompileTo('not-in-each');
    end

    it 'each on Set' do
      skip
      var set = Set.new([1, 2, 3]);

      expectTemplate('{{#each set}}{{@key}}(i{{@index}}) {{.}} {{/each}}')
        .withInput({ set: set })
        .toCompileTo('0(i0) 1 1(i1) 2 2(i2) 3 ');

      expectTemplate('{{#each set}}{{#if @first}}{{.}}{{/if}}{{/each}}')
        .withInput({ set: set })
        .toCompileTo('1');

      expectTemplate('{{#each set}}{{#if @last}}{{.}}{{/if}}{{/each}}')
        .withInput({ set: set })
        .toCompileTo('3');

      expectTemplate('{{#each set}}{{.}}{{/each}}not-in-each')
        .withInput({ set: Set.new })
        .toCompileTo('not-in-each');
    end

    if true || global.Symbol&.iterator
      it 'each on iterable' do
        skip
        function Iterator(arr) {
          this.arr = arr;
          this.index = 0;
        }
        Iterator.prototype.next = lambda {
          var value = this.arr[this.index];
          var done = this.index === this.arr.length;
          this.index += 1 if !done
          return { value: value, done: done };
        };
        function Iterable(arr) {
          this.arr = arr;
        }
        Iterable.prototype[global.Symbol.iterator] = lambda {
          return new Iterator(this.arr);
        };
        var string = '{{#each goodbyes}}{{text}}! {{/each}}cruel {{world}}!';

        expectTemplate(string)
          .withInput({
            goodbyes: Iterable.new([
              { text: 'goodbye' },
              { text: 'Goodbye' },
              { text: 'GOODBYE' },
            ]),
            world: 'world',
          })
          .withMessage(
            'each with array argument iterates over the contents when not empty'
          )
          .toCompileTo('goodbye! Goodbye! GOODBYE! cruel world!');

        expectTemplate(string)
          .withInput({
            goodbyes: Iterable.new([]),
            world: 'world',
          })
          .withMessage(
            'each with array argument ignores the contents when empty'
          )
          .toCompileTo('cruel world!');
      end
    end
  end

  describe '#log' do
    # /* eslint-disable no-console */
    # if (typeof console === 'undefined')
    #   return;
    # end

    # var $log, $info, $error;
    before do
      # $log = console.log;
      # $info = console.info;
      # $error = console.error;
    end
    after do
      # console.log = $log;
      # console.info = $info;
      # console.error = $error;
    end

    it 'should call logger at default level' do
      skip
      # var levelArg, logArg;
      # handlebarsEnv.log = lambda { |level, arg|
      #   levelArg = level;
      #   logArg = arg;
      # };

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .withMessage('log should not display')
        .toCompileTo('');
      equals(1, levelArg, 'should call log with 1');
      equals('whee', logArg, "should call log with 'whee'");
    end

    it 'should call logger at data level' do
      skip
      # var levelArg, logArg;
      # handlebarsEnv.log = lambda { |level, arg|
      #   levelArg = level;
      #   logArg = arg;
      # };

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .withRuntimeOptions({ data: { level: '03' } })
        .withCompileOptions({ data: true })
        .toCompileTo('');
      equals('03', levelArg);
      equals('whee', logArg);
    end

    it 'should output to info' do
      skip
      var called;

      # console.info = lambda { |info|
      #   equals('whee', info);
      #   called = true;
      #   console.info = $info;
      #   console.log = $log;
      # };
      # console.log = lambda { |log|
      #   equals('whee', log);
      #   called = true;
      #   console.info = $info;
      #   console.log = $log;
      # };

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .toCompileTo('');
      equals(true, called);
    end

    it 'should log at data level' do
      skip
      var called;

      # console.error = lambda { |log|
      #   equals('whee', log);
      #   called = true;
      #   console.error = $error;
      # };

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .withRuntimeOptions({ data: { level: '03' } })
        .withCompileOptions({ data: true })
        .toCompileTo('');
      equals(true, called);
    end

    it 'should handle missing logger' do
      skip
      var called = false;

      console.error = undefined;
      # console.log = lambda { |log|
      #   equals('whee', log);
      #   called = true;
      #   console.log = $log;
      # };

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .withRuntimeOptions({ data: { level: '03' } })
        .withCompileOptions({ data: true })
        .toCompileTo('');
      equals(true, called);
    end

    it 'should handle string log levels' do
      skip
      var called;

      # console.error = lambda { |log|
      #   equals('whee', log);
      #   called = true;
      # };

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .withRuntimeOptions({ data: { level: 'error' } })
        .withCompileOptions({ data: true })
        .toCompileTo('');
      equals(true, called);

      called = false;

      expectTemplate('{{log blah}}')
        .withInput({ blah: 'whee' })
        .withRuntimeOptions({ data: { level: 'ERROR' } })
        .withCompileOptions({ data: true })
        .toCompileTo('');
      equals(true, called);
    end

    it 'should handle hash log levels' do
      skip
      var called;

      # console.error = lambda { |log|
      #   equals('whee', log);
      #   called = true;
      # };

      expectTemplate('{{log blah level="error"}}')
        .withInput({ blah: 'whee' })
        .toCompileTo('');
      equals(true, called);
    end

    it 'should handle hash log levels' do
      skip
      var called = false;

      # console.info =
      #   console.log =
      #   console.error =
      #   console.debug =
      #     lambda {
      #       called = true;
      #       console.info = console.log = console.error = console.debug = $log;
      #     };

      expectTemplate('{{log blah level="debug"}}')
        .withInput({ blah: 'whee' })
        .toCompileTo('');
      equals(false, called);
    end

    it 'should pass multiple log arguments' do
      skip
      var called;

      # console.info = console.log = lambda { |log1, log2, log3|
      #   equals('whee', log1);
      #   equals('foo', log2);
      #   equals(1, log3);
      #   called = true;
      #   console.log = $log;
      # };

      expectTemplate('{{log blah "foo" 1}}')
        .withInput({ blah: 'whee' })
        .toCompileTo('');
      equals(true, called);
    end

    it 'should pass zero log arguments' do
      skip
      var called;

      # console.info = console.log = lambda {
      #   expect(arguments.length).to.equal(0);
      #   called = true;
      #   console.log = $log;
      # };

      expectTemplate('{{log}}').withInput({ blah: 'whee' }).toCompileTo('');
      expect(called).to.be.true;
    end
    # /* eslint-enable no-console */
  end

  describe '#lookup' do
    it 'should lookup arbitrary content' do
      skip
      expectTemplate('{{#each goodbyes}}{{lookup ../data .}}{{/each}}')
        .withInput({ goodbyes: [0, 1], data: ['foo', 'bar'] })
        .toCompileTo('foobar');
    end

    it 'should not fail on undefined value' do
      skip
      expectTemplate('{{#each goodbyes}}{{lookup ../bar .}}{{/each}}')
        .withInput({ goodbyes: [0, 1], data: ['foo', 'bar'] })
        .toCompileTo('');
    end
  end
  # rubocop:enable Style/WordArray
  # rubocop:enable Style/TrailingCommaInHashLiteral
  # rubocop:enable Style/TrailingCommaInArrayLiteral
  # rubocop:enable Style/Semicolon
  # rubocop:enable Style/RedundantReturn
  # rubocop:enable Style/NegatedIf
  # rubocop:enable Layout/LineLength
  # rubocop:enable Layout/FirstArrayElementIndentation
  # rubocop:enable Layout/FirstHashElementIndentation
end
# rubocop:enable Style/StringLiterals
