# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'caprese/version'

Gem::Specification.new do |spec|
  spec.name          = "caprese"
  spec.version       = Caprese::VERSION
  spec.authors       = ["Nick Landgrebe", "Pelle ten Cate", "Kieran Klaassen"]
  spec.email         = ["nick@landgre.be"]

  spec.summary       = "Opinionated Rails library for writing RESTful APIs"
  spec.license       = "MIT"

  spec.homepage      = 'https://github.com/nicklandgrebe/caprese'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.1'

  spec.add_dependency 'active_model_serializers', '0.10.7'
  spec.add_dependency 'kaminari', '>= 0.17.0'
  spec.add_dependency 'rails', '>= 5.2.0', '< 6.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'factory_girl'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.6.0'
  spec.add_development_dependency 'rspec-rails', '~> 3.6.0'
  spec.add_development_dependency 'sqlite3'
end
