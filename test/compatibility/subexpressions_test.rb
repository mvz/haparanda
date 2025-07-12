# frozen_string_literal: true

require "test_helper"

# Based on spec/subexpressions.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/subexpressions.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'subexpressions' do
  it 'arg-less helper' do
    expectTemplate('{{foo (bar)}}!')
      .withHelpers({
        foo: lambda { |val|
          return val + val;
        },
        bar: lambda {
          return 'LOL';
        },
      })
      .toCompileTo('LOLLOL!');
  end

  it 'helper w args' do
    expectTemplate('{{blog (equal a b)}}')
      .withInput({ bar: 'LOL' })
      .withHelpers({
        blog: lambda { |val|
          return 'val is ' + val.to_s;
        },
        equal: lambda { |x, y|
          return x == y;
        },
      })
      .toCompileTo('val is true');
  end

  it 'mixed paths and helpers' do
    expectTemplate('{{blog baz.bat (equal a b) baz.bar}}')
      .withInput({ bar: 'LOL', baz: { bat: 'foo!', bar: 'bar!' } })
      .withHelpers({
        blog: lambda { |val, that, theOther|
          return 'val is ' + val.to_s + ', ' + that.to_s + ' and ' + theOther.to_s;
        },
        equal: lambda { |x, y|
          return x == y;
        },
      })
      .toCompileTo('val is foo!, true and bar!');
  end

  it 'supports much nesting' do
    expectTemplate('{{blog (equal (equal true true) true)}}')
      .withInput({ bar: 'LOL' })
      .withHelpers({
        blog: lambda { |val|
          return 'val is ' + val.to_s;
        },
        equal: lambda { |x, y|
          return x == y;
        },
      })
      .toCompileTo('val is true');
  end

  it 'GH-800 : Complex subexpressions' do
    context = { a: 'a', b: 'b', c: { c: 'c' }, d: 'd', e: { e: 'e' } };
    helpers = {
      dash: lambda { |a, b|
        return a + '-' + b;
      },
      concat: lambda { |a, b|
        return a + b;
      },
    };

    expectTemplate("{{dash 'abc' (concat a b)}}")
      .withInput(context)
      .withHelpers(helpers)
      .toCompileTo('abc-ab');

    expectTemplate('{{dash d (concat a b)}}')
      .withInput(context)
      .withHelpers(helpers)
      .toCompileTo('d-ab');

    expectTemplate('{{dash c.c (concat a b)}}')
      .withInput(context)
      .withHelpers(helpers)
      .toCompileTo('c-ab');

    expectTemplate('{{dash (concat a b) c.c}}')
      .withInput(context)
      .withHelpers(helpers)
      .toCompileTo('ab-c');

    expectTemplate('{{dash (concat a e.e) c.c}}')
      .withInput(context)
      .withHelpers(helpers)
      .toCompileTo('ae-c');
  end

  it 'provides each nested helper invocation its own options hash' do
    lastOptions = nil;
    helpers = {
      equal: lambda { |x, y, options|
        if !options || options == lastOptions
          throw new Error('options hash was reused');
        end
        lastOptions = options;
        return x == y;
      },
    };
    expectTemplate('{{equal (equal true true) true}}')
      .withHelpers(helpers)
      .toCompileTo('true');
  end

  it 'with hashes' do
    expectTemplate("{{blog (equal (equal true true) true fun='yes')}}")
      .withInput({ bar: 'LOL' })
      .withHelpers({
        blog: lambda { |val|
          return 'val is ' + val.to_s;
        },
        equal: lambda { |x, y|
          return x == y;
        },
      })
      .toCompileTo('val is true');
  end

  it 'as hashes' do
    expectTemplate("{{blog fun=(equal (blog fun=1) 'val is 1')}}")
      .withHelpers({
        blog: lambda { |options|
          return 'val is ' + options.hash[:fun].to_s;
        },
        equal: lambda { |x, y|
          return x == y;
        },
      })
      .toCompileTo('val is true');
  end

  it 'multiple subexpressions in a hash' do
    expectTemplate(
      '{{input aria-label=(t "Name") placeholder=(t "Example User")}}'
    )
      .withHelpers({
        input: lambda { |options|
          hash = options.hash;
          ariaLabel = Haparanda::HandlebarsProcessor::Utils.escape(hash[:'aria-label']);
          placeholder = Haparanda::HandlebarsProcessor::Utils.escape(hash[:placeholder]);
          return Haparanda::HandlebarsProcessor::SafeString.new(
            '<input aria-label="' +
              ariaLabel +
              '" placeholder="' +
              placeholder +
              '" />'
          );
        },
        t: lambda { |defaultString|
          return Haparanda::HandlebarsProcessor::SafeString.new(defaultString);
        },
      })
      .toCompileTo('<input aria-label="Name" placeholder="Example User" />');
  end

  it 'multiple subexpressions in a hash with context' do
    expectTemplate(
      '{{input aria-label=(t item.field) placeholder=(t item.placeholder)}}'
    )
      .withInput({
        item: {
          field: 'Name',
          placeholder: 'Example User',
        },
      })
      .withHelpers({
        input: lambda { |options|
          hash = options.hash;
          ariaLabel = Haparanda::HandlebarsProcessor::Utils.escape(hash[:'aria-label']);
          placeholder = Haparanda::HandlebarsProcessor::Utils.escape(hash[:placeholder]);
          return Haparanda::HandlebarsProcessor::SafeString.new(
            '<input aria-label="' +
              ariaLabel +
              '" placeholder="' +
              placeholder +
              '" />'
          );
        },
        t: lambda { |defaultString|
          return Haparanda::HandlebarsProcessor::SafeString.new(defaultString);
        },
      })
      .toCompileTo('<input aria-label="Name" placeholder="Example User" />');
  end

  it 'subexpression functions on the context' do
    expectTemplate('{{foo (bar)}}!')
      .withInput({
        bar: lambda {
          return 'LOL';
        },
      })
      .withHelpers({
        foo: lambda { |val|
          return val + val;
        },
      })
      .toCompileTo('LOLLOL!');
  end

  it "subexpressions can't just be property lookups" do
    expectTemplate('{{foo (bar)}}!')
      .withInput({
        bar: 'LOL',
      })
      .withHelpers({
        foo: lambda { |val|
          return val + val;
        },
      })
      .toThrow(NoMethodError);
  end
end
