# frozen_string_literal: true

require_relative "../../../test_helper"

class AlignMethodsTest < Minitest::Test
  include CopHelper

  def cop_class
    RuboCop::Cop::Tablecop::AlignMethods
  end

  # ===========================================================================
  # Basic Alignment - Endless Methods
  # ===========================================================================

  def test_aligns_endless_methods
    source = <<~RUBY
      def foo = 1
      def barbaz = 2
    RUBY

    expected = <<~RUBY
      def foo    = 1
      def barbaz = 2
    RUBY

    assert_correction(source, expected)
  end

  def test_aligns_endless_methods_with_args
    source = <<~RUBY
      def add(a, b) = a + b
      def multiply(x, y, z) = x * y * z
    RUBY

    expected = <<~RUBY
      def add(a, b)         = a + b
      def multiply(x, y, z) = x * y * z
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Basic Alignment - Traditional One-liners
  # ===========================================================================

  def test_aligns_traditional_oneliners
    source = <<~RUBY
      def foo() 1 end
      def barbaz() 2 end
    RUBY

    expected = <<~RUBY
      def foo()    1 end
      def barbaz() 2 end
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Mixed Endless and Traditional
  # ===========================================================================

  def test_aligns_mixed_endless_and_traditional
    source = <<~RUBY
      def foo = 1
      def bar() 2 end
      def quxxy = 3
    RUBY

    # Body starts should align
    expected = <<~RUBY
      def foo   = 1
      def bar()   2 end
      def quxxy = 3
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Non-contiguous Methods (should not align across gaps)
  # ===========================================================================

  def test_does_not_align_across_blank_lines
    source = <<~RUBY
      def foo = 1
      def barbaz = 2

      def x = 10
      def yz = 20
    RUBY

    expected = <<~RUBY
      def foo    = 1
      def barbaz = 2

      def x  = 10
      def yz = 20
    RUBY

    assert_correction(source, expected)
  end

  def test_does_not_align_across_comments
    source = <<~RUBY
      def foo = 1
      def barbaz = 2
      # a comment
      def x = 10
      def yz = 20
    RUBY

    expected = <<~RUBY
      def foo    = 1
      def barbaz = 2
      # a comment
      def x  = 10
      def yz = 20
    RUBY

    assert_correction(source, expected)
  end

  def test_does_not_align_across_multiline_methods
    source = <<~RUBY
      def foo = 1
      def barbaz = 2
      def complex
        do_something
        do_more
      end
      def x = 10
      def yz = 20
    RUBY

    expected = <<~RUBY
      def foo    = 1
      def barbaz = 2
      def complex
        do_something
        do_more
      end
      def x  = 10
      def yz = 20
    RUBY

    assert_correction(source, expected)
  end

  # ===========================================================================
  # Line Length Limits
  # ===========================================================================

  def test_no_alignment_if_would_exceed_line_length
    # With 80 char limit, the short method's line would exceed 80 if aligned
    # short line: "def x = " + 45 padding + body = way over 80
    source = <<~RUBY
      def x = "a short value that still takes up some space in the line"
      def this_is_an_extremely_long_method_name_that_will_cause_issues = "b"
    RUBY

    # If we padded "def x" to align with the long name, the first line would be:
    # "def x" + ~60 spaces + " = " + "a short value..." = way over 80
    # So no alignment should happen
    assert_no_offenses(source)
  end

  # ===========================================================================
  # Edge Cases
  # ===========================================================================

  def test_single_method_no_alignment_needed
    source = <<~RUBY
      def foo = 1
    RUBY

    assert_no_offenses(source)
  end

  def test_already_aligned
    source = <<~RUBY
      def foo    = 1
      def barbaz = 2
    RUBY

    assert_no_offenses(source)
  end

  def test_handles_operator_methods
    # Note: def []= cannot be endless (Ruby syntax limitation)
    source = <<~RUBY
      def +(other) = @val + other.val
      def -(other) = @val - other.val
      def inspect = "Thing"
    RUBY

    # +(other) and -(other) both have = at column 13, inspect has = at column 12
    # So only inspect needs 1 space of padding
    expected = <<~RUBY
      def +(other) = @val + other.val
      def -(other) = @val - other.val
      def inspect  = "Thing"
    RUBY

    assert_correction(source, expected)
  end

  def test_handles_predicate_methods
    source = <<~RUBY
      def empty? = @items.empty?
      def valid? = @errors.none?
      def admin_user? = role == :admin
    RUBY

    expected = <<~RUBY
      def empty?      = @items.empty?
      def valid?      = @errors.none?
      def admin_user? = role == :admin
    RUBY

    assert_correction(source, expected)
  end

  def test_handles_bang_methods
    source = <<~RUBY
      def save! = persist || raise("Failed")
      def validate! = check_all!
    RUBY

    # save! = at col 10, validate! = at col 14
    # save! needs 4 spaces padding
    expected = <<~RUBY
      def save!     = persist || raise("Failed")
      def validate! = check_all!
    RUBY

    assert_correction(source, expected)
  end

  def test_respects_indentation
    source = <<~RUBY
      class Foo
        def bar = 1
        def quxxy = 2
      end
    RUBY

    expected = <<~RUBY
      class Foo
        def bar   = 1
        def quxxy = 2
      end
    RUBY

    assert_correction(source, expected)
  end

  def test_methods_at_different_indent_levels_not_aligned
    source = <<~RUBY
      class Foo
        def bar = 1

        class Inner
          def x = 10
          def yz = 20
        end

        def qux = 3
      end
    RUBY

    expected = <<~RUBY
      class Foo
        def bar = 1

        class Inner
          def x  = 10
          def yz = 20
        end

        def qux = 3
      end
    RUBY

    assert_correction(source, expected)
  end
end
