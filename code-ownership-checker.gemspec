# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'code/ownership/checker/version'

Gem::Specification.new do |spec|
  spec.name          = 'code-ownership-checker'
  spec.version       = Code::Ownership::Checker::VERSION
  spec.authors       = ['Jônatas Davi Paganini']
  spec.email         = ['jonatas.paganini@toptal.com']

  spec.summary       = 'Check consistency of Github CODEOWNERS and git changes.'
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^bin\/code-owners-checker/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'fuzzy_match'
  spec.add_dependency 'git'
  spec.add_dependency 'thor'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
end
