# frozen_string_literal: true

module RuboCop
  module Cop
    module Tablecop
      # Aligns contiguous single-line method definitions so their bodies start
      # at the same column. Aligns on `=` for endless methods; traditional
      # one-liners align as if they had an invisible `=`.
      #
      # @example
      #   # bad
      #   def foo = 1
      #   def barbaz = 2
      #
      #   # good
      #   def foo    = 1
      #   def barbaz = 2
      #
      # @example Mixed endless and traditional
      #   # bad
      #   def foo = 1
      #   def bar() 2 end
      #
      #   # good
      #   def foo   = 1
      #   def bar()   2 end
      #
      class AlignMethods < Base
        extend AutoCorrector

        MSG = "Align method body with other methods in group"

        def on_new_investigation
          return if processed_source.blank?

          groups = find_method_groups
          groups.each { |group| check_group(group) }
        end

        private

        def find_method_groups
          methods = single_line_methods
          return [] if methods.empty?

          groups = []
          current_group = [methods.first]

          methods.each_cons(2) do |prev, curr|
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

        def single_line_methods
          return [] unless processed_source.ast

          processed_source.ast.each_descendant(:def).select(&:single_line?).sort_by(&:first_line)
        end

        def consecutive_lines?(prev_node, curr_node)
          curr_node.first_line == prev_node.last_line + 1
        end

        def same_indent?(node1, node2)
          node1.loc.keyword.column == node2.loc.keyword.column
        end

        def check_group(group)
          # Calculate the column of `=` (or where `=` would be) for each method
          eq_cols = group.map { |node| equals_column(node) }
          max_eq_col = eq_cols.max

          # Check if alignment would exceed line length for any method
          return unless can_align_all?(group, eq_cols, max_eq_col)

          group.each_with_index do |node, idx|
            padding_needed = max_eq_col - eq_cols[idx]
            next if padding_needed <= 0

            register_offense(node, padding_needed)
          end
        end

        # Returns the column where `=` is (endless) or would be (traditional)
        def equals_column(node)
          if node.endless?
            node.loc.assignment.column
          else
            # For traditional: body column - 2 (pretend there's ` = ` before body)
            # Actually, we want to align bodies, so use body column directly
            # but we insert padding before body, effectively making ` = ` align
            node.body.loc.expression.column - 2
          end
        end

        # Position to insert padding
        def padding_insert_position(node)
          if node.endless?
            node.loc.assignment.begin_pos
          else
            node.body.loc.expression.begin_pos
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
