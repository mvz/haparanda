# Haparanda

by Matijs van Zuijlen

## Description

Pure Ruby Handlebars Parser using upstream .l and .y files

## Usage

```ruby
require "haparanda"

hbs = Haparanda::Compiler.new
hbs.register_partial 'full_name', "{{person.first_name}} {{person.last_name}}"
hbs.register_helper :foo do |context, bar, baz, options|
  ...
end
template = hbs.compile(template_text) # Returns Haparanda::Template
template.call input  # or template.call({ foo: "Bar", baz: "Qux" })
```

## Goals

- Fast parsing
- Implement all of handlebars

## Compatibility Notes

- When using a hash as input, symbols keys and string keys are considered different
- Currently targets handlebars.js master

## Install

```bash
gem install haparanda
```

## Related Work

- The [handlebars](https://rubygems.org/gems/handlebars) gem is a wrapper
  around the JavaScript library. It seems to support all of handlebars.
  However, it requires a separate javascript runtime and suffers from memory
  leaks.

  handlebars-rb uses the following API:

  ```ruby
  handlebars = Handlebars::Context.new
  handlebars.register_helper(:foo) do
    ...
  end
  template = handlebars.compile("{{say}} {{what}}")
  template.call(:say => "Hey", :what => "Yuh!") #=> "Hey Yuh!"
  ```

- Alternative gems that also use the JavaScript implementation are
  [handlebars_exec](https://github.com/vibes/handlebars_exec),
  [minibars](https://github.com/combinaut/minibars) and
  [handlebars-engine](https://github.com/gi/handlebars-ruby).

- [ruby-handlebars](https://github.com/smartbear/ruby-handlebars) is a pure
  Ruby handlebars parser that uses the [parslet](https://github.com/kschiess/parslet/)
  gem for parsing. Parsing is slow for large templates and it does not
  implement whitespace handling.

  It uses the following API:

  ```ruby
  hbs = Handlebars::Handlebars.new
  hbs.register_partial('full_name', "{{person.first_name}} {{person.last_name}}")
  hbs.register_helper(:foo) do |context, bar, baz, block, else_block|
    ...
  end
  template = hbs.compile("Hello {{> full_name}}")
  template.call({person: {first_name: 'Pinkie', last_name: 'Pie'}})
  ```

- [curlybars](https://github.com/zendesk/curlybars) is a pure Ruby parser aimed
  at using handlebars templates with Rails. It uses [RLTK](https://github.com/chriswailes/RLTK)
  for parsing and supports a subset of handlebars. In particular, it seems
  custom block helpers are not supported.

- [FlavourSaver](https://github.com/FlavourSaver/FlavourSaver) is a pure Ruby
  Handlebars parser that also uses [RLTK](https://github.com/chriswailes/RLTK).
  It provides a [Tilt](https://github.com/jeremyevans/tilt) based interface.
  This is the most complete Ruby implementation of Handlebars but unfortunately
  parsing is slow.

- [Steering](https://github.com/pixeltrix/steering) is a compiler for
  handlebars templates. Also uses the JavaScript handlebars implementation.

## License

Copyright &copy; 2024&ndash;2025 [Matijs van Zuijlen](http://www.matijs.net)

Haparanda is free software, distributed under the terms of the GNU Lesser
General Public License, version 2.1 or later. See the file COPYING.LIB for
more information.

Several files are based on code from handlebars-js and handlebars-parser. These
are each individually marked in comments at the top of the file.

Handlebars-js is released under the MIT license:

Copyright (C) 2011-2019 by Yehuda Katz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

handlebars-parser is released under the ICS license.
