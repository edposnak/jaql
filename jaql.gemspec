# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jaql/version'

Gem::Specification.new do |spec|
  spec.name          = "jaql"
  spec.version       = Jaql::VERSION
  spec.authors       = ["Ed Posnak"]
  spec.email         = ["ed.posnak@gmail.com"]
  spec.summary       = %q{JSON query language in ruby}
  spec.description   = %q{JSON query language implementation using postgres JSON functions}
  spec.homepage      = "https://github.com/edposnak"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'abstract_method', '~> 1.2'
  spec.add_dependency 'adamantium', '~> 0'

  spec.add_dependency 'activesupport', '> 3'
  spec.add_development_dependency 'pg', '~> 0.18'
  spec.add_dependency 'dart', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
