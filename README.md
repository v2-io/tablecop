# Tablecop

RuboCop extension for table-like, condensed Ruby formatting.

## Installation

Add to your Gemfile:

```ruby
gem "tablecop", path: "~/src/tablecop"  # local development
# gem "tablecop"                         # once published
```

## Usage

Add to your `.rubocop.yml`:

```yaml
# RuboCop 1.72+ (plugin system)
plugins:
  - tablecop

# Or for older RuboCop versions
require:
  - tablecop
```

## Cops

### Tablecop/CondenseWhen

Condenses multi-line `when` clauses to single lines when possible.

```ruby
# bad
case foo
when 1
  "one"
when 2
  "two"
end

# good
case foo
when 1 then "one"
when 2 then "two"
end
```

The cop respects `Layout/LineLength` and won't condense if it would exceed the max line length.

Multi-statement bodies, heredocs, and bodies with comments are left alone:

```ruby
# left alone (multiple statements)
case foo
when 1
  do_something
  do_something_else
end

# left alone (heredoc)
case foo
when 1
  <<~MSG
    Hello
  MSG
end
```

## Future Cops

Ideas for additional table-oriented cops:

- **CondenseIf** - Single-line if/unless when body is simple
- **AlignAssignments** - Vertical alignment of `=` in consecutive assignments
- **AlignHashValues** - Align hash values in table format

## License

MIT
