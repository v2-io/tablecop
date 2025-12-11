# frozen_string_literal: true

require_relative "../../../test_helper"

class CondenseWhenTest < Minitest::Test
  include CopHelper

  def cop_class
    RuboCop::Cop::Tablecop::CondenseWhen
  end

  # ===========================================================================
  # Basic Condensing (existing behavior)
  # ===========================================================================

  def test_condenses_simple_when_clauses
    source = <<~RUBY
      case foo
      when 1
        "one"
      when 2
        "two"
      end
    RUBY

    expected = <<~RUBY
      case foo
      when 1 then "one"
      when 2 then "two"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_leaves_complex_bodies_alone
    source = <<~RUBY
      case foo
      when 1
        do_something
        do_something_else
      end
    RUBY

    assert_no_offenses(source)
  end

  def test_leaves_heredocs_alone
    source = <<~RUBY
      case foo
      when 1
        <<~MSG
          Hello
        MSG
      end
    RUBY

    assert_no_offenses(source)
  end

  def test_leaves_already_condensed_alone
    source = <<~RUBY
      case foo
      when 1 then "one"
      when 2 then "two"
      end
    RUBY

    assert_no_offenses(source)
  end

  # ===========================================================================
  # Alignment (new behavior)
  # ===========================================================================

  def test_aligns_then_keywords_across_siblings
    source = <<~RUBY
      case foo
      when 1
        "one"
      when 200
        "two hundred"
      when :other
        "other"
      end
    RUBY

    # All `then` keywords should align to the longest condition
    expected = <<~RUBY
      case foo
      when 1      then "one"
      when 200    then "two hundred"
      when :other then "other"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_aligns_with_multiple_conditions
    source = <<~RUBY
      case foo
      when 1, 2
        "small"
      when 100, 200, 300
        "large"
      end
    RUBY

    expected = <<~RUBY
      case foo
      when 1, 2          then "small"
      when 100, 200, 300 then "large"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_aligns_with_mixed_condensable_and_not
    # When some clauses can't be condensed, still align the ones that can
    source = <<~RUBY
      case foo
      when 1
        "one"
      when 2
        do_something
        do_something_else
      when 300
        "three hundred"
      end
    RUBY

    # when 2 stays multi-line, but 1 and 300 should align with each other
    expected = <<~RUBY
      case foo
      when 1   then "one"
      when 2
        do_something
        do_something_else
      when 300 then "three hundred"
      end
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Line Length Handling
  # ===========================================================================

  def test_no_alignment_if_would_exceed_line_length
    # With 80 char limit, if alignment would push any line over,
    # fall back to no-alignment condensing
    source = <<~RUBY
      case foo
      when 1
        "this is a pretty long result string here"
      when :a_long_condition_name_for_testing
        "x"
      end
    RUBY

    # Aligned version would pad "1" to match the long condition,
    # pushing first line over 80 chars. So fall back to no alignment.
    expected = <<~RUBY
      case foo
      when 1 then "this is a pretty long result string here"
      when :a_long_condition_name_for_testing then "x"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_skips_clause_entirely_if_condensed_exceeds_line_length
    # If even unaligned condensing would exceed line length, leave it multi-line
    source = <<~RUBY
      case foo
      when 1
        "one"
      when :x
        "this is a very long result string that would exceed the line length limit"
      end
    RUBY

    # First one condenses, second stays multi-line (too long even without alignment)
    expected = <<~RUBY
      case foo
      when 1 then "one"
      when :x
        "this is a very long result string that would exceed the line length limit"
      end
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_handles_else_clause
    source = <<~RUBY
      case foo
      when 1
        "one"
      when 2
        "two"
      else
        "other"
      end
    RUBY

    # else stays as-is, whens get aligned
    expected = <<~RUBY
      case foo
      when 1 then "one"
      when 2 then "two"
      else
        "other"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_handles_empty_else
    source = <<~RUBY
      case foo
      when 1
        "one"
      else
      end
    RUBY

    expected = <<~RUBY
      case foo
      when 1 then "one"
      else
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_handles_single_when
    source = <<~RUBY
      case foo
      when 1
        "one"
      end
    RUBY

    expected = <<~RUBY
      case foo
      when 1 then "one"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_preserves_comments_in_multiline_whens
    source = <<~RUBY
      case foo
      when 1
        # This is important
        "one"
      when 2
        "two"
      end
    RUBY

    # when 1 has a comment, so it stays multi-line
    # when 2 can be condensed
    expected = <<~RUBY
      case foo
      when 1
        # This is important
        "one"
      when 2 then "two"
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_skips_when_with_if_else_body
    # if/else in body can't be safely condensed without adding semicolons
    source = <<~RUBY
      case op
      when :is_nil
        if filter[:value]
          ds.where(attr => nil)
        else
          ds.exclude(attr => nil)
        end
      when :eq
        ds.where(attr => value)
      end
    RUBY

    # when :is_nil stays multi-line (complex if/else),
    # when :eq can be condensed
    expected = <<~RUBY
      case op
      when :is_nil
        if filter[:value]
          ds.where(attr => nil)
        else
          ds.exclude(attr => nil)
        end
      when :eq then ds.where(attr => value)
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_allows_single_line_ternary_in_body
    source = <<~RUBY
      case foo
      when 1
        x ? "yes" : "no"
      when 2
        "two"
      end
    RUBY

    expected = <<~RUBY
      case foo
      when 1 then x ? "yes" : "no"
      when 2 then "two"
      end
    RUBY

    assert_correction(source, expected)
  end

  # TODO: Nested cases cause clobbering errors - needs special handling
  # def test_nested_case_statements
  #   source = <<~RUBY
  #     case foo
  #     when 1
  #       case bar
  #       when :a
  #         "a"
  #       when :bbb
  #         "b"
  #       end
  #     when 2
  #       "two"
  #     end
  #   RUBY
  #
  #   # Inner case gets aligned separately from outer
  #   expected = <<~RUBY
  #     case foo
  #     when 1
  #       case bar
  #       when :a   then "a"
  #       when :bbb then "b"
  #       end
  #     when 2 then "two"
  #     end
  #   RUBY
  #
  #   assert_correction(source, expected)
  # end

end
