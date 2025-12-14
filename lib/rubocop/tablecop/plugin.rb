# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Tablecop
    # Integrates rubocop-tablecop with RuboCop's plugin system.
    #
    # This plugin provides cops for table-like, condensed Ruby formatting:
    # - AlignAssignments: Align consecutive assignments on the = operator
    # - AlignMethods: Align contiguous single-line method definitions
    # - CondenseWhen: Condense multi-line when clauses to single lines
    # - SafeEndlessMethod: Convert methods to endless form safely
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-tablecop",
          version: Version::STRING,
          homepage: "https://github.com/v2-io/tablecop",
          description: "Table-like, condensed Ruby formatting cops."
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
