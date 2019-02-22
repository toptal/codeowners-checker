# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'codeowners/checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'codeowners-checker'
  spec.version       = Codeowners::Checker::VERSION
  spec.authors       = ['Jônatas Davi Paganini', 'Eva Kadlecová', 'Michal Papis']
  spec.email         = ['bootcamp_team@toptal.com']

  spec.summary       = 'Check consistency of Github CODEOWNERS and git changes.'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = ['codeowners-checker']
  spec.require_paths = ['lib']

  spec.add_dependency 'fuzzy_match', '~> 2.1'
  spec.add_dependency 'git', '~> 1.5'
  spec.add_dependency 'thor', '~> 0.20.3'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'pry', '~> 0.12.2'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rb-readline', '~> 0.5.5'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.61.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.30'
  spec.add_development_dependency 'simplecov', '~> 0.16.1'
end
