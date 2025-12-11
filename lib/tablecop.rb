# frozen_string_literal: true

require "rubocop"

require_relative "tablecop/version"
require_relative "rubocop/cop/tablecop_cops"

# Inject default configuration when loaded via `require: tablecop`
RuboCop::ConfigLoader.inject_defaults!(File.join(__dir__, ".."))
