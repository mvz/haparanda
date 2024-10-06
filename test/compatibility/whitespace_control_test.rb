# frozen_string_literal: true

require "test_helper"

# Based on spec/whitespace-control.js in handlebars.js. The content of the specs should
# mostly be identical to the content there, so a side-by-side diff should show
# spec equivalence, and show any new specs that should be added.
#
# spec/whitespace-control.js in handlebars.js is covered by the MIT license. See README.md
# for details.

describe 'whitespace control' do
  it 'should strip whitespace around mustache calls' do
    hash = { foo: 'bar<' };

    expectTemplate(' {{~foo~}} ').withInput(hash).toCompileTo('bar&lt;');

    expectTemplate(' {{~foo}} ').withInput(hash).toCompileTo('bar&lt; ');

    expectTemplate(' {{foo~}} ').withInput(hash).toCompileTo(' bar&lt;');

    expectTemplate(' {{~&foo~}} ').withInput(hash).toCompileTo('bar<');

    expectTemplate(' {{~{foo}~}} ').withInput(hash).toCompileTo('bar<');

    expectTemplate('1\n{{foo~}} \n\n 23\n{{bar}}4').toCompileTo('1\n23\n4');
  end

  describe 'blocks' do
    it 'should strip whitespace around simple block calls' do
      hash = { foo: 'bar<' };

      expectTemplate(' {{~#if foo~}} bar {{~/if~}} ')
        .withInput(hash)
        .toCompileTo('bar');

      expectTemplate(' {{#if foo~}} bar {{/if~}} ')
        .withInput(hash)
        .toCompileTo(' bar ');

      expectTemplate(' {{~#if foo}} bar {{~/if}} ')
        .withInput(hash)
        .toCompileTo(' bar ');

      expectTemplate(' {{#if foo}} bar {{/if}} ')
        .withInput(hash)
        .toCompileTo('  bar  ');

      expectTemplate(' \n\n{{~#if foo~}} \n\nbar \n\n{{~/if~}}\n\n ')
        .withInput(hash)
        .toCompileTo('bar');

      expectTemplate(' a\n\n{{~#if foo~}} \n\nbar \n\n{{~/if~}}\n\na ')
        .withInput(hash)
        .toCompileTo(' abara ');
    end

    it 'should strip whitespace around inverse block calls' do
      expectTemplate(' {{~^if foo~}} bar {{~/if~}} ').toCompileTo('bar');

      expectTemplate(' {{^if foo~}} bar {{/if~}} ').toCompileTo(' bar ');

      expectTemplate(' {{~^if foo}} bar {{~/if}} ').toCompileTo(' bar ');

      expectTemplate(' {{^if foo}} bar {{/if}} ').toCompileTo('  bar  ');

      expectTemplate(
        ' \n\n{{~^if foo~}} \n\nbar \n\n{{~/if~}}\n\n '
      ).toCompileTo('bar');
    end

    it 'should strip whitespace around complex block calls' do
      hash = { foo: 'bar<' };

      expectTemplate('{{#if foo~}} bar {{~^~}} baz {{~/if}}')
        .withInput(hash)
        .toCompileTo('bar');

      expectTemplate('{{#if foo~}} bar {{^~}} baz {{/if}}')
        .withInput(hash)
        .toCompileTo('bar ');

      expectTemplate('{{#if foo}} bar {{~^~}} baz {{~/if}}')
        .withInput(hash)
        .toCompileTo(' bar');

      expectTemplate('{{#if foo}} bar {{^~}} baz {{/if}}')
        .withInput(hash)
        .toCompileTo(' bar ');

      expectTemplate('{{#if foo~}} bar {{~else~}} baz {{~/if}}')
        .withInput(hash)
        .toCompileTo('bar');

      expectTemplate(
        '\n\n{{~#if foo~}} \n\nbar \n\n{{~^~}} \n\nbaz \n\n{{~/if~}}\n\n'
      )
        .withInput(hash)
        .toCompileTo('bar');

      expectTemplate(
        '\n\n{{~#if foo~}} \n\n{{{foo}}} \n\n{{~^~}} \n\nbaz \n\n{{~/if~}}\n\n'
      )
        .withInput(hash)
        .toCompileTo('bar<');

      expectTemplate('{{#if foo~}} bar {{~^~}} baz {{~/if}}').toCompileTo(
        'baz'
      );

      expectTemplate('{{#if foo}} bar {{~^~}} baz {{/if}}').toCompileTo('baz ');

      expectTemplate('{{#if foo~}} bar {{~^}} baz {{~/if}}').toCompileTo(
        ' baz'
      );

      expectTemplate('{{#if foo~}} bar {{~^}} baz {{/if}}').toCompileTo(
        ' baz '
      );

      expectTemplate('{{#if foo~}} bar {{~else~}} baz {{~/if}}').toCompileTo(
        'baz'
      );

      expectTemplate(
        '\n\n{{~#if foo~}} \n\nbar \n\n{{~^~}} \n\nbaz \n\n{{~/if~}}\n\n'
      ).toCompileTo('baz');
    end
  end

  it 'should strip whitespace around partials' do
    skip
    expectTemplate('foo {{~> dude~}} ')
      .withPartials({ dude: 'bar' })
      .toCompileTo('foobar');

    expectTemplate('foo {{> dude~}} ')
      .withPartials({ dude: 'bar' })
      .toCompileTo('foo bar');

    expectTemplate('foo {{> dude}} ')
      .withPartials({ dude: 'bar' })
      .toCompileTo('foo bar ');

    expectTemplate('foo\n {{~> dude}} ')
      .withPartials({ dude: 'bar' })
      .toCompileTo('foobar');

    expectTemplate('foo\n {{> dude}} ')
      .withPartials({ dude: 'bar' })
      .toCompileTo('foo\n bar');
  end

  it 'should only strip whitespace once' do
    skip
    expectTemplate(' {{~foo~}} {{foo}} {{foo}} ')
      .withInput({ foo: 'bar' })
      .toCompileTo('barbar bar ');
  end
end
