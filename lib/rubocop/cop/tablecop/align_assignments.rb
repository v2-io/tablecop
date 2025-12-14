# frozen_string_literal: true

module RuboCop
  module Cop
    module Tablecop
      # Aligns consecutive assignment statements on the `=` operator.
      #
      # Handles simple assignments (`=`), compound assignments (`||=`, `&&=`, `+=`, etc.),
      # and constant assignments. Skips lines containing heredocs entirely to avoid
      # infinite loops with Layout/SpaceAroundOperators.
      #
      # @example
      #   # bad
      #   x = 1
      #   foo = 2
      #   barbaz = 3
      #
      #   # good
      #   x      = 1
      #   foo    = 2
      #   barbaz = 3
      #
      # @example Compound operators
      #   # bad
      #   data ||= attrs
      #   options = default
      #
      #   # good
      #   data    ||= attrs
      #   options = default
      #
      class AlignAssignments < Base
        extend AutoCorrector

        MSG = "Align assignment with other assignments in group"

        # Assignment types we handle
        ASSIGNMENT_TYPES = %i[lvasgn ivasgn cvasgn gvasgn casgn op_asgn or_asgn and_asgn].freeze

        def on_new_investigation
          return if processed_source.blank?

          groups = find_assignment_groups
          groups.each { |group| check_group(group) }
        end

        private

        def find_assignment_groups
          assignments = find_assignments
          return [] if assignments.empty?

          groups = []
          current_group = [assignments.first]

          assignments.each_cons(2) do |prev, curr|
            if consecutive_lines?(prev, curr) && same_indent?(prev, curr)
              current_group << curr
            else
              groups << current_group if current_group.size > 1
              current_group = [curr]
            end
          end

          groups << current_group if current_group.size > 1
          groups
        end

        def find_assignments
          return [] unless processed_source.ast

          assignments = []

          processed_source.ast.each_node(*ASSIGNMENT_TYPES) do |node|
            # Skip if this assignment contains a heredoc
            next if contains_heredoc?(node)

            # Skip multi-assignment (a, b = ...)
            # These have parent :mlhs (multiple left-hand side)
            next if node.parent&.type == :masgn || node.parent&.type == :mlhs

            # Skip inner lvasgn/ivasgn that are part of op_asgn/or_asgn/and_asgn
            # (these compound assignments have the simple asgn as first child)
            next if node.parent&.type&.to_s&.end_with?("_asgn") &&
                    %i[lvasgn ivasgn cvasgn gvasgn].include?(node.type)

            # Skip array/hash element assignment (hash[:key] = val)
            # These are actually send nodes with :[]= method
            next if node.type == :send && node.method_name == :[]=

            # Only include if it's on a single line
            next unless node.single_line?

            # Skip assignments inside blocks - they shouldn't align with
            # assignments outside the block
            next if inside_block?(node)

            assignments << node
          end

          assignments.sort_by(&:first_line)
        end

        def consecutive_lines?(prev_node, curr_node)
          curr_node.first_line == prev_node.last_line + 1
        end

        def same_indent?(node1, node2)
          indent(node1) == indent(node2)
        end

        def indent(node)
          processed_source.lines[node.first_line - 1] =~ /\S/
        end

        def check_group(group)
          eq_cols = group.map { |node| equals_column(node) }
          max_eq_col = eq_cols.max

          return unless can_align_all?(group, eq_cols, max_eq_col)

          group.each_with_index do |node, idx|
            padding_needed = max_eq_col - eq_cols[idx]
            next if padding_needed <= 0

            register_offense(node, padding_needed)
          end
        end

        def equals_column(node)
          case node.type
          when :lvasgn, :ivasgn, :cvasgn, :gvasgn
            # Simple assignment: variable = value
            # The operator loc is not directly available, find it from source
            find_operator_column(node)
          when :casgn
            # Constant assignment: CONST = value
            find_operator_column(node)
          when :op_asgn, :or_asgn, :and_asgn
            # Compound assignment: var += val, var ||= val, var &&= val
            node.loc.operator.column
          else
            find_operator_column(node)
          end
        end

        def find_operator_column(node)
          # For simple assignments, find the = in the source
          line = processed_source.lines[node.first_line - 1]

          # Find the first = that's part of an assignment (not ==, !=, etc.)
          # Start after the LHS
          lhs_end = lhs_end_column(node)

          # Search for = after LHS
          rest_of_line = line[lhs_end..]
          eq_match = rest_of_line&.match(/\s*(=)(?!=)/)

          if eq_match
            lhs_end + eq_match.begin(1)
          else
            # Fallback: use the LHS end position
            lhs_end
          end
        end

        def lhs_end_column(node)
          case node.type
          when :lvasgn
            node.loc.name.end_pos - processed_source.buffer.line_range(node.first_line).begin_pos
          when :ivasgn, :cvasgn, :gvasgn
            node.loc.name.end_pos - processed_source.buffer.line_range(node.first_line).begin_pos
          when :casgn
            node.loc.name.end_pos - processed_source.buffer.line_range(node.first_line).begin_pos
          else
            0
          end
        end

        def padding_insert_position(node)
          case node.type
          when :op_asgn, :or_asgn, :and_asgn
            node.loc.operator.begin_pos
          else
            # For simple assignments, insert before the =
            line = processed_source.lines[node.first_line - 1]
            line_start = processed_source.buffer.line_range(node.first_line).begin_pos
            lhs_end = lhs_end_column(node)

            rest_of_line = line[lhs_end..]
            eq_match = rest_of_line&.match(/\s*(=)(?!=)/)

            if eq_match
              line_start + lhs_end + eq_match.begin(1)
            else
              line_start + lhs_end
            end
          end
        end

        def can_align_all?(group, eq_cols, max_eq_col)
          group.each_with_index.all? do |node, idx|
            padding = max_eq_col - eq_cols[idx]
            line_length(node) + padding <= max_line_length
          end
        end

        def line_length(node)
          processed_source.lines[node.first_line - 1].length
        end

        def contains_heredoc?(node)
          return false unless node

          node.each_descendant(:str, :dstr, :xstr).any? do |str_node|
            str_node.heredoc?
          end
        end

        def inside_block?(node)
          node.each_ancestor(:block, :numblock).any?
        end

        def register_offense(node, padding_needed)
          add_offense(node) do |corrector|
            pos = padding_insert_position(node)
            corrector.insert_before(
              Parser::Source::Range.new(processed_source.buffer, pos, pos),
              " " * padding_needed
            )
          end
        end

        def max_line_length
          config.for_cop("Layout/LineLength")["Max"] || 120
        end
      end
    end
  end
end
