# frozen_string_literal: true

require_relative "lib/rubocop/tablecop/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-tablecop"
  spec.version = RuboCop::Tablecop::VERSION
  spec.authors = ["Joseph Wecker"]
  spec.email = ["joseph@v2.io"]

  spec.summary = "RuboCop extension for table-like, condensed Ruby formatting"
  spec.description = "Custom RuboCop cops that enforce vertical alignment and condensed single-line expressions where appropriate."
  spec.homepage = "https://github.com/v2-io/tablecop"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*", "config/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rubocop", ">= 1.50"
  spec.add_dependency "lint_roller", "~> 1.1"
end
