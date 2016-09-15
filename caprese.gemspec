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

  spec.add_dependency "rails", ">= 4.2.0"
  spec.add_dependency 'active_model_serializers', '~> 0.10.0'

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
