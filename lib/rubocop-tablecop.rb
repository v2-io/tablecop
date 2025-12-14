# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/tablecop/version"
require_relative "rubocop/cop/tablecop_cops"

# Inject default configuration when loaded as a plugin
RuboCop::ConfigLoader.inject_defaults!(File.join(__dir__, "..", "config", "default.yml"))
