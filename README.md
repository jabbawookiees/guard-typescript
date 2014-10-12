# Guard::TypeScript

Guard::TypeScript compiles or validates your TypeScripts automatically when files are modified.

This is a clone of [Guard CoffeeScript](https://github.com/guard/guard-coffeescript) that was shamelessly stolen 
and modified to work with TypeScript.

If you have any questions please join us on our [Google group](http://groups.google.com/group/guard-dev) or on `#guard`
(irc.freenode.net).

## Install

The simplest way to install Guard is to use [Bundler](http://gembundler.com/).
Please make sure to have [Guard](https://github.com/guard/guard) installed.

Add Guard::TypeScript to your `Gemfile`:

```ruby
group :development do
  gem 'guard-typescript'
end
```
Add the default Guard::TypeScript template to your `Guardfile` by running:

```bash
$ guard init typescript
```

## JSON

The JSON library is also required but is not explicitly stated as a gem dependency. If you're on Ruby 1.8 you'll need
to install the `json` or `json_pure` gem. On Ruby 1.9, JSON is included in the standard library.

## TypeScript

Guard::TypeScript uses [Typescript Node](https://github.com/typescript-ruby/typescript-node-ruby) to compile the TypeScripts.

## Usage

Please read the [Guard usage documentation](https://github.com/guard/guard#readme).

## Guardfile

Guard::TypeScript can be adapted to all kind of projects. Please read the
[Guard documentation](https://github.com/guard/guard#readme) for more information about the Guardfile DSL.

### Ruby project

In a Ruby project you want to configure your input and output directories.

```ruby
guard 'typescript', :input => 'typescripts', :output => 'javascripts'
```

If your output directory is the same as the input directory, you can simply skip it:

```ruby
guard 'typescript', :input => 'javascripts'
```

### Rails app with the asset pipeline

With the introduction of the [asset pipeline](http://guides.rubyonrails.org/asset_pipeline.html) in Rails 3.1 there is
no need to compile your TypeScripts with this Guard.

However, if you would still like to have feedback on the validation of your TypeScripts
(preferably with a Growl notification) directly after you save a change, then you can still
use this Guard and simply skip generation of the output file:

```ruby
guard 'typescript', :input => 'app/assets/javascripts', :noop => true
```

This give you a faster compilation feedback compared to making a subsequent request to your Rails application. If you
just want to be notified when an error occurs you can hide the success compilation message:

```ruby
guard 'typescript', :input => 'app/assets/javascripts', :noop => true, :hide_success => true
```

### Rails app without the asset pipeline

Without the asset pipeline you just define an input and output directory like within a normal Ruby project:

```ruby
guard 'typescript', :input => 'app/typescripts', :output => 'public/javascripts'
```

## Options

There following options can be passed to Guard::TypeScript:

```ruby
:input => 'typescripts'             # Relative path to the input directory.
                                    # Files will be added that match end in .ts
                                    # default: nil

:output => 'javascripts'            # Relative path to the output directory.
                                    # default: the path given with the :input option

:noop => true                       # No operation: do not write an output file.
                                    # Warning: Actually compiles the file and deletes the result.
                                    # default: false

:shallow => true                    # Do not create nested output directories.
                                    # default: false

:source_map => true                 # Do create the source map file.
                                    # default: false

:hide_success => true               # Disable successful compilation messages.
                                    # default: false

:all_on_start => true               # Regenerate all files on startup
                                    # default: false

:error_to_js => true                # Print the Typescript error message directly in
                                    # the JavaScript file
                                    # default: false
```

### Output short notation

In addition to the standard configuration, this Guard has a short notation for configure projects with a single input
and output directory. This notation creates a watcher from the `:input` parameter that matches all TypeScript files
under the given directory and you don't have to specify a watch regular expression.

```ruby
guard 'typescript', :input => 'javascripts'
```

### Nested directories

The Guard detects by default nested directories and creates these within the output directory. The detection is based on
the match of the watch regular expression:

A file

```ruby
/app/typescripts/ui/buttons/toggle_button.ts
```

that has been detected by the watch

```ruby
watch(%r{^app/typescripts/(.+\.ts)$})
```

with an output directory of

```ruby
:output => 'public/javascripts/compiled'
```

will be compiled to

```ruby
public/javascripts/compiled/ui/buttons/toggle_button.js
```

Note the parenthesis around the `.+\.ts`. This enables Guard::TypeScript to place the full path that was matched
inside the parenthesis into the proper output directory.

This behavior can be switched off by passing the option `:shallow => true` to the Guard, so that all JavaScripts will be
compiled directly to the output directory.

### Multiple source directories

The Guard short notation

```ruby
guard 'typescript', :input => 'app/typescripts', :output => 'public/javascripts/compiled'
```

will be internally converted into the standard notation by adding `/(.+\.ts)` to the `input` option string and
create a Watcher that is equivalent to:

```ruby
guard 'typescript', :output => 'public/javascripts/compiled' do
  watch(%r{^app/typescripts/(.+\.ts)$})
end
```

To add a second source directory that will be compiled to the same output directory, just add another watcher:

```ruby
guard 'typescript', :input => 'app/typescripts', :output => 'public/javascripts/compiled' do
  watch(%r{lib/typescripts/(.+\.ts)})
end
```

which is equivalent to:

```ruby
guard 'typescript', :output => 'public/javascripts/compiled' do
  watch(%r{app/typescripts/(.+\.ts)})
  watch(%r{lib/typescripts/(.+\.ts)})
end
```

## Issues

You can report issues and feature requests to [GitHub Issues](https://github.com/jabbawookiees/guard-typescript/issues). Try to figure out
where the issue belongs to: Is it an issue with Guard itself or with a Guard::TypeScript?

When you file an issue, please try to follow to these simple rules if applicable:

* Make sure you run Guard with `bundle exec` first.
* Add debug information to the issue by running Guard with the `--debug` option.
* Add your `Guardfile` and `Gemfile` to the issue.
* Make sure that the issue is reproducible with your description.

## Development

- Source hosted at [GitHub](https://github.com/jabbawookiees/guard-typescript).

Pull requests are very welcome! Please try to follow these simple rules if applicable:

* Please create a topic branch for every separate change you make.
* Make sure your patches are well tested.
* Update the [Yard](http://yardoc.org/) documentation.
* Update the README.
* Update the CHANGELOG for noteworthy changes.
* Please **do not change** the version number.

For questions please join us in our [Google group](http://groups.google.com/group/guard-dev) or on
`#guard` (irc.freenode.net).

## Author

Developed by Payton Yao.

## Contributors

See the GitHub list of [contributors](https://github.com/jabbawookiees/guard-typescript/contributors).

## Acknowledgment

* [Michael Kessler](https://twitter.com/#!/netzpirat) for [Guard CoffeeScript](https://github.com/netzpirat/guard-coffeescript/),
from which this was shamelessly stolen from and modified to work with TypeScript.
* The [Guard Team](https://github.com/guard/guard/contributors) for giving us such a nice piece of software
that is so easy to extend, one *has* to make a plugin for it!
* All the authors of the numerous [Guards](https://github.com/guard) available for making the Guard ecosystem
so much growing and comprehensive.

## License

(The MIT License)

Copyright (c) 2014 Payton Yao

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.