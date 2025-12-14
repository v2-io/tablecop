# Upgrading rubocop-tablecop to Plugin System

## Background

RuboCop 1.72+ introduced a new plugin system based on `lint_roller`. The current
implementation uses the legacy `require:` directive in .rubocop.yml, which works
but doesn't integrate with the modern `plugins:` system.

The plugin system provides:
- Automatic discovery via gemspec metadata
- Standardized configuration injection
- Better integration with RuboCop's tooling

## Current State

```
lib/
  rubocop-tablecop.rb           # Entry point, uses ConfigLoader.inject_defaults!
  rubocop/
    tablecop/
      version.rb                # RuboCop::Tablecop::VERSION = "0.1.1"
    cop/
      tablecop_cops.rb          # Requires all cops
      tablecop/
        align_assignments.rb
        align_methods.rb
        condense_when.rb
        safe_endless_method.rb
config/
  default.yml                   # Cop configurations
```

Usage in .rubocop.yml (legacy):
```yaml
require:
  - rubocop-tablecop
```

## Target State

```
lib/
  rubocop-tablecop.rb           # Entry point (simplified)
  rubocop/
    tablecop.rb                 # NEW: Namespace module
    tablecop/
      version.rb                # Version with STRING constant
      plugin.rb                 # NEW: LintRoller::Plugin subclass
    cop/
      tablecop_cops.rb
      tablecop/
        align_assignments.rb
        align_methods.rb
        condense_when.rb
        safe_endless_method.rb
config/
  default.yml
```

Usage in .rubocop.yml (plugin):
```yaml
plugins:
  - rubocop-tablecop
```

## Implementation Steps

### 1. Create namespace module

Create `lib/rubocop/tablecop.rb`:

```ruby
# frozen_string_literal: true

module RuboCop
  # RuboCop Tablecop project namespace.
  module Tablecop
  end
end
```

### 2. Update version module

Update `lib/rubocop/tablecop/version.rb` to use STRING constant (conventional):

```ruby
# frozen_string_literal: true

module RuboCop
  module Tablecop
    module Version
      STRING = '0.2.0'

      def self.document_version
        STRING.match('\d+\.\d+').to_s
      end
    end

    # For backwards compatibility
    VERSION = Version::STRING
  end
end
```

### 3. Create plugin class

Create `lib/rubocop/tablecop/plugin.rb`:

```ruby
# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Tablecop
    # Integrates rubocop-tablecop with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-tablecop',
          version: Version::STRING,
          homepage: 'https://github.com/v2-io/tablecop',
          description: 'Table-like, condensed Ruby formatting cops.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end
```

### 4. Update entry point

Update `lib/rubocop-tablecop.rb`:

```ruby
# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/tablecop'
require_relative 'rubocop/tablecop/version'
require_relative 'rubocop/tablecop/plugin'
require_relative 'rubocop/cop/tablecop_cops'
```

Note: Remove the `ConfigLoader.inject_defaults!` call - the plugin's `rules`
method now handles configuration injection.

### 5. Update gemspec metadata

Update `rubocop-tablecop.gemspec`:

```ruby
spec.metadata["default_lint_roller_plugin"] = "RuboCop::Tablecop::Plugin"

# Update minimum RuboCop version for plugin support
spec.add_dependency "rubocop", ">= 1.72"
spec.add_dependency "lint_roller", "~> 1.1"
```

### 6. Update version

Bump to 0.2.0 to indicate the plugin system migration.

## Verification

After implementation:

1. Build and install gem locally:
   ```
   gem build rubocop-tablecop.gemspec
   gem install rubocop-tablecop-0.2.0.gem
   ```

2. Test plugin loading in archema:
   ```yaml
   # .rubocop.yml
   plugins:
     - rubocop-minitest
     - rubocop-tablecop
   ```

3. Verify cops are registered:
   ```
   bundle exec rubocop --only Tablecop -L
   ```

4. Verify backwards compatibility (require should still work):
   ```yaml
   require:
     - rubocop-tablecop
   ```

## File Changes Summary

| File | Action |
|------|--------|
| `lib/rubocop/tablecop.rb` | Create (namespace module) |
| `lib/rubocop/tablecop/plugin.rb` | Create (plugin class) |
| `lib/rubocop/tablecop/version.rb` | Update (add Version module with STRING) |
| `lib/rubocop-tablecop.rb` | Update (add requires, remove inject_defaults!) |
| `rubocop-tablecop.gemspec` | Update (add metadata, bump rubocop requirement) |

## Breaking Changes

- Minimum RuboCop version increases from 1.50 to 1.72
- Users on older RuboCop versions will need to continue using `require:`

## References

- [RuboCop Plugin Migration Guide](https://docs.rubocop.org/rubocop/plugin_migration_guide.html)
- [lint_roller gem](https://github.com/standardrb/lint_roller)
- [rubocop-minitest plugin implementation](https://github.com/rubocop/rubocop-minitest)
