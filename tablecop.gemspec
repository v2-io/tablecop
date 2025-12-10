# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "tablecop"
  spec.version = "0.1.0"
  spec.authors = ["Joseph Wecker"]
  spec.email = ["joseph@wecker.io"]

  spec.summary = "RuboCop extension for table-like, condensed Ruby formatting"
  spec.description = "Custom RuboCop cops that enforce vertical alignment and condensed single-line expressions where appropriate."
  spec.homepage = "https://github.com/josephwecker/tablecop"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "config/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rubocop", ">= 1.50"
  spec.add_dependency "lint_roller", "~> 1.1"
end
