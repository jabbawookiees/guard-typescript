# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/typescript/version'

Gem::Specification.new do |s|
  s.name        = 'guard-typescript'
  s.version     = Guard::TypeScriptVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Payton Yao']
  s.email       = ['payton.yao@gmail.com']
  s.homepage    = 'http://github.com/jabbawookiees/guard-typescript'
  s.summary     = 'Guard gem for TypeScript'
  s.description = 'Guard::TypeScript automatically generates JavaScripts from your TypeScripts'
  s.license = 'MIT'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = 'guard-typescript'

  s.add_dependency 'guard', '>= 1.1.0'
  s.add_dependency 'ruby-typescript', '>= 0.1.0'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rspec'

  s.files        = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
end
