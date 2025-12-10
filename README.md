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

## Built-in Cop Defaults

Tablecop also sets opinionated defaults for RuboCop's built-in cops to achieve a table-like, condensed style:

- **Layout/HashAlignment** - `table` style for vertical alignment
- **Layout/FirstArrayElementIndentation** - `consistent` (not aligned to brackets)
- **Layout/FirstArgumentIndentation** - `consistent`
- **Layout/ExtraSpacing** - Allow alignment spacing
- **Style/EndlessMethod** - **Disabled** (has critical autocorrect bugs)

See `config/default.yml` for the full list.

## Known Issues

RuboCop has several autocorrect bugs that can destroy code:

| Bug | Cop | Impact |
|-----|-----|--------|
| Heredoc destruction | `Style/EndlessMethod` | Deletes heredoc content |
| `\|\|=` breaking | `Layout/ExtraSpacing` | Syntax errors |
| Rescue orphaning | `Style/EndlessMethod` | Code structure destroyed |
| Infinite loops | `Layout/HashAlignment` | Process hangs |

Tablecop's defaults disable or work around these where possible. See [docs/known-issues.md](docs/known-issues.md) for details.

## Future Cops

Ideas for additional table-oriented cops:

- **CondenseIf** - Single-line if/unless when body is simple
- **SafeEndlessMethod** - Endless methods that actually check for heredocs/rescue first
- **AlignAssignments** - Vertical alignment that handles `||=` correctly

## License

MIT
