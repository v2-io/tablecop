# frozen_string_literal: true

module RuboCop
  module Cop
    module Tablecop
      # Checks for multi-line `when` clauses that could be condensed to a single
      # line using the `then` keyword.
      #
      # This cop encourages a table-like, vertically-aligned style for case
      # statements where each when clause fits on one line.
      #
      # @example
      #   # bad
      #   case foo
      #   when 1
      #     "one"
      #   when 2
      #     "two"
      #   end
      #
      #   # good
      #   case foo
      #   when 1 then "one"
      #   when 2 then "two"
      #   end
      #
      #   # also good (body too complex for single line)
      #   case foo
      #   when 1
      #     do_something
      #     do_something_else
      #   end
      #
      # @example MaxLineLength: 80 (default from Layout/LineLength)
      #   # If the condensed line would exceed MaxLineLength, no offense is registered.
      #
      class CondenseWhen < Base
        extend AutoCorrector

        MSG = "Condense `when` to single line: `when %<conditions>s then %<body>s`"

        def on_when(node)
          return unless condensable?(node)

          conditions_source = node.conditions.map(&:source).join(", ")
          body_source = node.body.source.gsub(/\s*\n\s*/, " ").strip
          single_line = "when #{conditions_source} then #{body_source}"

          # Check line length
          base_indent = node.loc.keyword.column
          return if (base_indent + single_line.length) > max_line_length

          message = format(MSG, conditions: conditions_source, body: body_source)

          add_offense(node, message: message) do |corrector|
            corrector.replace(node, single_line)
          end
        end

        private

        def condensable?(node)
          # Skip if already single-line
          return false if node.single_line?

          # Must have a body
          return false unless node.body

          # Body must be a simple single expression (not begin block with multiple statements)
          return false if node.body.begin_type? && node.body.children.size > 1

          # No heredocs
          return false if contains_heredoc?(node.body)

          # No multi-line strings
          return false if contains_multiline_string?(node.body)

          # No comments between when and body
          return false if comment_between?(node)

          # Conditions must be on one line
          return false unless conditions_single_line?(node)

          true
        end

        def conditions_single_line?(node)
          return true if node.conditions.size == 1

          first_cond = node.conditions.first
          last_cond = node.conditions.last
          first_cond.first_line == last_cond.last_line
        end

        def contains_heredoc?(node)
          return false unless node

          # Check the node itself if it's a string type
          return true if node.respond_to?(:heredoc?) && node.heredoc?

          node.each_descendant(:str, :dstr, :xstr).any?(&:heredoc?)
        end

        def contains_multiline_string?(node)
          return false unless node

          node.each_descendant(:str, :dstr).any? do |str_node|
            next false if str_node.heredoc?

            str_node.source.include?("\n")
          end
        end

        def comment_between?(when_node)
          return false unless when_node.body

          comments = processed_source.comments
          when_line = when_node.loc.keyword.line
          body_line = when_node.body.first_line

          comments.any? do |comment|
            comment.loc.line.between?(when_line, body_line - 1)
          end
        end

        def max_line_length
          config.for_cop("Layout/LineLength")["Max"] || 120
        end
      end
    end
  end
end
