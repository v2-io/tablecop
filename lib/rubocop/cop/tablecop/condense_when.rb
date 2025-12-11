# frozen_string_literal: true

module RuboCop
  module Cop
    module Tablecop
      # Checks for multi-line `when` clauses that could be condensed to a single
      # line using the `then` keyword, and aligns `then` keywords across siblings.
      #
      # This cop encourages a table-like, vertically-aligned style for case
      # statements where each when clause fits on one line.
      #
      # @example
      #   # bad
      #   case foo
      #   when 1
      #     "one"
      #   when 200
      #     "two hundred"
      #   end
      #
      #   # good (aligned)
      #   case foo
      #   when 1   then "one"
      #   when 200 then "two hundred"
      #   end
      #
      #   # also good (body too complex for single line)
      #   case foo
      #   when 1
      #     do_something
      #     do_something_else
      #   end
      #
      class CondenseWhen < Base
        extend AutoCorrector

        MSG = "Condense `when` to single line with aligned `then`"

        def on_case(node)
          when_nodes = node.when_branches
          return if when_nodes.empty?

          # Analyze which whens can be condensed
          condensable = when_nodes.map { |w| [w, condensable?(w)] }

          # If none can be condensed, nothing to do
          return unless condensable.any? { |_, can| can }

          # Calculate alignment width from all condensable whens
          max_condition_width = calculate_max_condition_width(condensable)

          # Check if alignment would exceed line length for any condensable when
          use_alignment = can_align_all?(condensable, max_condition_width, node)

          # Register offenses and corrections for each condensable when
          condensable.each do |when_node, can_condense|
            next unless can_condense
            next if when_node.single_line?  # Already condensed

            register_offense(when_node, max_condition_width, use_alignment, node)
          end
        end

        private

        def condensable?(node)
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

          # Check if condensed form would exceed line length (without alignment)
          single_line = build_single_line(node, 0)
          base_indent = node.loc.keyword.column
          return false if (base_indent + single_line.length) > max_line_length

          true
        end

        def calculate_max_condition_width(condensable)
          condensable
            .select { |_, can| can }
            .map { |w, _| condition_width(w) }
            .max || 0
        end

        def condition_width(when_node)
          when_node.conditions.map(&:source).join(", ").length
        end

        def can_align_all?(condensable, max_width, case_node)
          base_indent = case_node.loc.keyword.column

          condensable.all? do |when_node, can_condense|
            next true unless can_condense
            next true if when_node.single_line?

            # Check if aligned version fits
            single_line = build_single_line(when_node, max_width)
            (base_indent + single_line.length) <= max_line_length
          end
        end

        def build_single_line(when_node, pad_to_width)
          conditions_source = when_node.conditions.map(&:source).join(", ")
          body_source = when_node.body.source.gsub(/\s*\n\s*/, " ").strip

          if pad_to_width > 0
            padding = " " * (pad_to_width - conditions_source.length)
            "when #{conditions_source}#{padding} then #{body_source}"
          else
            "when #{conditions_source} then #{body_source}"
          end
        end

        def register_offense(when_node, max_width, use_alignment, _case_node)
          add_offense(when_node) do |corrector|
            width = use_alignment ? max_width : 0
            single_line = build_single_line(when_node, width)
            corrector.replace(when_node, single_line)
          end
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
