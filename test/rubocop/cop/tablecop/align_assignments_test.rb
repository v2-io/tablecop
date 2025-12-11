# frozen_string_literal: true

require_relative "../../../test_helper"

class AlignAssignmentsTest < Minitest::Test
  include CopHelper

  def cop_class
    RuboCop::Cop::Tablecop::AlignAssignments
  end

  # ===========================================================================
  # Basic Alignment
  # ===========================================================================

  def test_aligns_simple_assignments
    source = <<~RUBY
      x = 1
      foo = 2
      barbaz = 3
    RUBY

    expected = <<~RUBY
      x      = 1
      foo    = 2
      barbaz = 3
    RUBY

    assert_correction(source, expected)
  end

  def test_aligns_assignments_with_different_values
    source = <<~RUBY
      name = "Alice"
      age = 30
      occupation = "Engineer"
    RUBY

    expected = <<~RUBY
      name       = "Alice"
      age        = 30
      occupation = "Engineer"
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Compound Assignment Operators
  # ===========================================================================

  def test_aligns_compound_operators
    source = <<~RUBY
      x += 1
      foo ||= default
      barbaz &&= check
    RUBY

    expected = <<~RUBY
      x      += 1
      foo    ||= default
      barbaz &&= check
    RUBY

    assert_correction(source, expected)
  end

  def test_aligns_mixed_simple_and_compound
    source = <<~RUBY
      data ||= attrs
      options = { actor: actor }
      managed = extract(data)
    RUBY

    expected = <<~RUBY
      data    ||= attrs
      options = { actor: actor }
      managed = extract(data)
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Heredocs - Skip Entirely
  # ===========================================================================

  def test_skips_heredoc_assignments
    source = <<~RUBY
      x = 1
      content = <<~TEXT
        Hello world
      TEXT
      y = 2
    RUBY

    # Heredoc line breaks the group - x and y aren't consecutive after skipping
    # So only check that we don't crash and don't break the heredoc
    # x is alone, content is skipped, y is alone
    assert_no_offenses(source)
  end

  def test_skips_heredoc_in_middle_of_group
    source = <<~RUBY
      a = 1
      b = 2
      msg = <<~TEXT
        Hello
      TEXT
      c = 3
      d = 4
    RUBY

    # a, b are one group; c, d are another (heredoc breaks continuity)
    expected = <<~RUBY
      a = 1
      b = 2
      msg = <<~TEXT
        Hello
      TEXT
      c = 3
      d = 4
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Non-contiguous Assignments
  # ===========================================================================

  def test_does_not_align_across_blank_lines
    source = <<~RUBY
      x = 1
      foo = 2

      a = 10
      barbaz = 20
    RUBY

    expected = <<~RUBY
      x   = 1
      foo = 2

      a      = 10
      barbaz = 20
    RUBY

    assert_correction(source, expected)
  end

  def test_does_not_align_across_other_statements
    source = <<~RUBY
      x = 1
      foo = 2
      do_something()
      a = 10
      barbaz = 20
    RUBY

    expected = <<~RUBY
      x   = 1
      foo = 2
      do_something()
      a      = 10
      barbaz = 20
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Line Length Limits
  # ===========================================================================

  def test_no_alignment_if_would_exceed_line_length
    source = <<~RUBY
      x = "a moderately long value that takes up space"
      this_is_an_extremely_long_variable_name = "short"
    RUBY

    # Aligning would push x's line way over 80 chars
    assert_no_offenses(source)
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_single_assignment_no_alignment_needed
    source = <<~RUBY
      x = 1
    RUBY

    assert_no_offenses(source)
  end

  def test_already_aligned
    source = <<~RUBY
      x      = 1
      foo    = 2
      barbaz = 3
    RUBY

    assert_no_offenses(source)
  end

  def test_respects_indentation
    source = <<~RUBY
      def foo
        x = 1
        barbaz = 2
      end
    RUBY

    expected = <<~RUBY
      def foo
        x      = 1
        barbaz = 2
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_different_indent_levels_not_aligned
    source = <<~RUBY
      x = 1
      if condition
        y = 2
        foo = 3
      end
      z = 4
    RUBY

    expected = <<~RUBY
      x = 1
      if condition
        y   = 2
        foo = 3
      end
      z = 4
    RUBY

    assert_correction(source, expected)
  end

  def test_handles_method_calls_on_lhs
    source = <<~RUBY
      @x = 1
      @foo = 2
      @barbaz = 3
    RUBY

    expected = <<~RUBY
      @x      = 1
      @foo    = 2
      @barbaz = 3
    RUBY

    assert_correction(source, expected)
  end

  def test_handles_array_access_on_lhs
    source = <<~RUBY
      hash[:a] = 1
      hash[:foo] = 2
      hash[:barbaz] = 3
    RUBY

    # These are actually method calls (:[]=), but they have = in them
    # We should skip these - they're not simple assignments
    assert_no_offenses(source)
  end

  def test_multi_assignment_skipped
    source = <<~RUBY
      a, b = [1, 2]
      x = 3
      foo = 4
    RUBY

    # Multi-assignment (masgn) breaks the group
    expected = <<~RUBY
      a, b = [1, 2]
      x   = 3
      foo = 4
    RUBY

    assert_correction(source, expected)
  end

  def test_constant_assignment
    source = <<~RUBY
      FOO = 1
      BARBAZ = 2
    RUBY

    expected = <<~RUBY
      FOO    = 1
      BARBAZ = 2
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Assignments Inside Blocks - Skipped
  # ===========================================================================

  def test_skips_assignments_inside_blocks
    source = <<~RUBY
      items.each { |item| count += 1 }
      total = 100
    RUBY

    # Block assignment shouldn't align with outside assignment
    assert_no_offenses(source)
  end

  def test_skips_assignments_inside_multiline_blocks
    source = <<~RUBY
      items.map do |item|
        x = item.value
        foo = item.name
      end
    RUBY

    # Assignments inside block - not aligned with anything outside
    # But they could align with each other IF we wanted to support that
    # For now, we skip all block assignments entirely
    assert_no_offenses(source)
  end

  def test_assignments_outside_block_still_align
    source = <<~RUBY
      x = 1
      foo = 2
      items.each { |i| count += 1 }
      a = 3
      barbaz = 4
    RUBY

    # x and foo should align; a and barbaz should align
    # Block in middle breaks the groups
    expected = <<~RUBY
      x   = 1
      foo = 2
      items.each { |i| count += 1 }
      a      = 3
      barbaz = 4
    RUBY

    assert_correction(source, expected)
  end
end
