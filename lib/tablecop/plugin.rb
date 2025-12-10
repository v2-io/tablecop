# frozen_string_literal: true

require "lint_roller"

module Tablecop
  # Plugin for RuboCop 1.72+ plugin system
  class Plugin < LintRoller::Plugin
    def about
      LintRoller::About.new(
        name: "tablecop",
        version: VERSION,
        homepage: "https://github.com/josephwecker/tablecop",
        description: "RuboCop extension for table-like, condensed Ruby formatting"
      )
    end

    def supported?(context)
      context.engine == :rubocop
    end

    def rules(_context)
      LintRoller::Rules.new(
        type: :path,
        config_format: :rubocop,
        value: File.expand_path("../../config/default.yml", __dir__)
      )
    end
  end
end
