# rubocop-tablecop

A RuboCop plugin for table-like, condensed Ruby formatting. Enforces vertical alignment and single-line expressions where they improve readability, while avoiding RuboCop's known autocorrect bugs.

## Installation

Add to your Gemfile:

```ruby
gem "rubocop-tablecop"
```

Then run:

```bash
bundle install
```

## Configuration

Add to your `.rubocop.yml`:

```yaml
# RuboCop 1.72+ (plugin system - recommended)
plugins:
  - rubocop-tablecop

# Or for older RuboCop versions
require:
  - rubocop-tablecop
```

The plugin requires **RuboCop >= 1.72**.

## Cops

### Tablecop/AlignAssignments

Aligns consecutive assignment statements on the `=` operator for improved readability.

**Enabled by default:** Yes

**Supports autocorrect:** Yes

**What it does:**
- Aligns consecutive assignments at the same indentation level
- Handles simple assignments (`=`), compound assignments (`||=`, `&&=`, `+=`, etc.), and constant assignments
- Skips lines containing heredocs to avoid infinite loops with other cops
- Respects `Layout/LineLength` configuration

**Examples:**

```ruby
# bad
x = 1
foo = 2
barbaz = 3

# good
x      = 1
foo    = 2
barbaz = 3
```

```ruby
# bad (compound operators)
data ||= attrs
options = default
config &&= fallback

# good
data    ||= attrs
options   = default
config  &&= fallback
```

**Limitations:**
- Skips assignments inside blocks
- Skips multi-assignment (`a, b = ...`)
- Skips assignments containing heredocs
- Only aligns assignments on consecutive lines at the same indentation level

### Tablecop/AlignMethods

Aligns contiguous single-line method definitions so their bodies start at the same column.

**Enabled by default:** Yes

**Supports autocorrect:** Yes

**What it does:**
- Aligns on `=` for endless methods
- Aligns traditional one-liners as if they had an invisible `=`
- Works with both instance and singleton methods
- Respects `Layout/LineLength` configuration

**Examples:**

```ruby
# bad
def foo = 1
def barbaz = 2

# good
def foo    = 1
def barbaz = 2
```

```ruby
# bad (mixed endless and traditional)
def foo = 1
def bar() 2 end

# good
def foo   = 1
def bar()   2 end
```

```ruby
# bad (singleton methods)
def self.x = 1
def self.longer_name = 2

# good
def self.x           = 1
def self.longer_name = 2
```

**Limitations:**
- Only aligns methods on consecutive lines at the same indentation level
- Only processes single-line methods

### Tablecop/CondenseWhen

Condenses multi-line `when` clauses to single lines using the `then` keyword and aligns them vertically.

**Enabled by default:** Yes

**Supports autocorrect:** Yes

**What it does:**
- Converts multi-line `when` clauses to single-line format with `then`
- Aligns `then` keywords across sibling `when` clauses for table-like appearance
- Only condenses when the result fits within `Layout/LineLength`
- Preserves complex bodies that shouldn't be condensed

**Examples:**

```ruby
# bad
case foo
when 1
  "one"
when 200
  "two hundred"
end

# good
case foo
when 1   then "one"
when 200 then "two hundred"
end
```

```ruby
# bad
case status
when :pending
  handle_pending
when :approved
  handle_approved
end

# good
case status
when :pending  then handle_pending
when :approved then handle_approved
end
```

**What it skips:**
- Multi-statement bodies
- Bodies with heredocs
- Bodies with multi-line strings
- Bodies with comments between `when` and body
- Complex control flow (multi-line `if`/`case`)
- Multi-statement blocks
- Cases where condensing would exceed line length

**Example of what's left alone:**

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

### Tablecop/SafeEndlessMethod

Converts multi-line single-expression methods to single-line form, avoiding all the known bugs in RuboCop's `Style/EndlessMethod`.

**Enabled by default:** Yes

**Supports autocorrect:** Yes

**What it does:**
- Converts simple multi-line methods to endless method syntax (`def foo = expr`)
- Falls back to traditional one-liner (`def foo() expr end`) for methods with modifier-if/unless that call other methods
- Avoids RuboCop's `Style/EndlessMethod` bugs:
  - Heredoc destruction
  - Rescue clause orphaning
  - module_eval context failures
  - Modifier-if with dynamic method failures

**Examples:**

```ruby
# bad
def foo
  42
end

# good
def foo = 42
```

```ruby
# bad
def calculate(x, y)
  x + y
end

# good
def calculate(x, y) = x + y
```

```ruby
# bad (modifier-if with method call)
def clear!
  data_layer.clear! if data_layer.respond_to?(:clear!)
end

# good (uses traditional one-liner to avoid bugs)
def clear!() data_layer.clear! if data_layer.respond_to?(:clear!) end
```

**What it skips:**
- Methods already on a single line
- Methods with multiple statements
- Methods with heredocs
- Methods with rescue/ensure clauses
- Setter methods (ending with `=`)
- Methods with multi-statement blocks
- Methods with complex control flow (multi-line `if`/`case`)
- Methods where condensing would exceed line length

## Built-in Cop Configuration

Tablecop sets opinionated defaults for RuboCop's built-in cops to achieve a table-like, condensed style. These are configured in `config/default.yml` and automatically applied when you use the plugin.

### Disabled Cops (Conflicts)

These cops are disabled because they conflict with Tablecop's alignment features:

```yaml
# Conflicts with Tablecop/AlignAssignments
Layout/SpaceAroundOperators:
  Enabled: false  # Enforces exactly one space, undoes alignment

# Conflicts with Tablecop/SafeEndlessMethod
Style/SingleLineDoEndBlock:
  Enabled: false  # Would reformat SafeEndlessMethod output

Style/SingleLineMethods:
  Enabled: false  # Would reformat SafeEndlessMethod output
```

### Disabled Cops (Known Bugs)

These cops have critical autocorrect bugs and are replaced by safer Tablecop equivalents:

```yaml
# REPLACED by Tablecop/SafeEndlessMethod
Style/EndlessMethod:
  Enabled: false  # Destroys heredocs, orphans rescue clauses

Style/AmbiguousEndlessMethodDefinition:
  Enabled: false  # Related to EndlessMethod issues

# BUGS: Creates syntax errors and silent logic bugs
Style/DoubleNegation:
  Enabled: false  # !!false ≠ !false.nil?

Style/HashExcept:
  Enabled: false  # Breaks mixed symbol/string key handling
```

### Layout Configuration

```yaml
Layout/HashAlignment:
  EnforcedHashRocketStyle: table
  EnforcedColonStyle: table
  EnforcedLastArgumentHashStyle: always_inspect

Layout/ExtraSpacing:
  AllowForAlignment: true
  AllowBeforeTrailingComments: true
  ForceEqualSignAlignment: false  # Would cause infinite loops with heredocs

Layout/FirstArrayElementIndentation:
  EnforcedStyle: consistent  # Not aligned to brackets

Layout/FirstArgumentIndentation:
  EnforcedStyle: consistent  # Not aligned to parens

Layout/SpaceInsideHashLiteralBraces:
  EnforcedStyle: space  # { foo: 1 } not {foo: 1}
```

See `config/default.yml` for the complete configuration.

## Known Issues

RuboCop has several autocorrect bugs that can destroy code. Tablecop's default configuration disables or works around these where possible. See [docs/known-issues.md](docs/known-issues.md) for detailed documentation of:

| Bug | Cop | Impact | Tablecop Mitigation |
|-----|-----|--------|---------------------|
| Heredoc destruction | `Style/EndlessMethod` | Data loss | Disabled; use `Tablecop/SafeEndlessMethod` |
| Rescue orphaning | `Style/EndlessMethod` | Scope/syntax errors | Disabled; use `Tablecop/SafeEndlessMethod` |
| module_eval failures | `Style/EndlessMethod` | Runtime NameError | Disabled; use `Tablecop/SafeEndlessMethod` |
| Modifier-if parse failures | `Style/EndlessMethod` | Parse-time NameError | Disabled; use `Tablecop/SafeEndlessMethod` |
| Heredoc alignment loop | `Layout/ExtraSpacing` | Process hangs | `ForceEqualSignAlignment: false` |
| `!!false` → `!false.nil?` | `Style/DoubleNegation` | Silent logic bug | Disabled |
| Mixed key types | `Style/HashExcept` | Data corruption | Disabled |

## Example Output

Here's what code looks like with Tablecop's formatting:

```ruby
# Method alignment
class Calculator
  def add(x, y)      = x + y
  def subtract(x, y) = x - y
  def multiply(x, y) = x * y
  def divide(x, y)   = x / y
end

# Assignment alignment
class Config
  BASE_URL    = "https://example.com"
  API_VERSION = "v1"
  TIMEOUT     = 30

  def initialize
    @cache   = {}
    @enabled = true
    @retries = 3
  end
end

# Case statement condensing
def status_message(status)
  case status
  when :pending   then "Waiting for approval"
  when :approved  then "Ready to proceed"
  when :rejected  then "Cannot continue"
  when :completed then "All done"
  end
end

# Hash alignment
config = {
  host:     "localhost",
  port:     3000,
  ssl:      true,
  timeout:  30,
  retries:  3,
  pool:     10
}
```

## Philosophy

Tablecop prioritizes:

1. **Vertical alignment** - Code aligned in columns is easier to scan
2. **Density** - Single-line expressions where appropriate reduce scrolling
3. **Safety** - Avoid RuboCop's known autocorrect bugs
4. **Readability** - Only condense when it improves clarity

This style works best for:
- Configuration files with many similar assignments
- Simple data transformations and mappings
- API clients with many similar methods
- DSLs with repetitive structures

This style may not work well for:
- Complex business logic with deep nesting
- Long method chains
- Files with highly variable line lengths

## Development

After checking out the repo, run `bundle install` to install dependencies. Then:

```bash
# Run RuboCop on the project
bundle exec rubocop

# Run autocorrect
bundle exec rubocop -a
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/v2-io/tablecop.

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
