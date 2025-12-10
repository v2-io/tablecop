# Known RuboCop Autocorrect Bugs

Documented bugs encountered when running `rubocop --autocorrect`. These are bugs in RuboCop itself (as of v1.81.7), not in Tablecop.

Tablecop's default configuration disables or avoids the problematic settings where possible.

---

## 1. Endless Methods with Heredocs

**Cop:** `Style/EndlessMethod`

**Bug:** Converts methods containing heredocs to endless method syntax, which destroys the heredoc content entirely.

**Before (valid):**
```ruby
def generate_migration(name)
  <<~RUBY
    # frozen_string_literal: true

    Sequel.migration do
      change do
        # ...
      end
    end
  RUBY
end
```

**After (broken - heredoc content deleted):**
```ruby
def generate_migration(name) = <<~RUBY
```

**Impact:** Complete data loss - the entire heredoc body is removed.

**Tablecop mitigation:** `Style/EndlessMethod` is disabled by default.

---

## 2. Alignment Breaking Compound Assignment Operators

**Cop:** `Layout/ExtraSpacing` with `ForceEqualSignAlignment: true`

**Bug:** When aligning consecutive assignments, it breaks compound operators like `||=` by inserting spaces between `||` and `=`.

**Before (valid):**
```ruby
data    ||= attrs
options   = { actor: actor }
```

**After (broken):**
```ruby
data    ||          = attrs
options             = { actor: actor }
```

**Impact:** Syntax error - `||=` is a single operator that cannot have whitespace.

**Tablecop mitigation:** `ForceEqualSignAlignment` is disabled by default.

---

## 3. Endless Methods in `module_eval` Contexts

**Cop:** `Style/EndlessMethod`

**Bug:** Endless methods that call other methods defined in the same dynamic context fail when the code is loaded via `module_eval` (used by Toys, some DSL frameworks).

**Before (valid):**
```ruby
mixin "my_mixin" do
  def project_root
    PROJECT_ROOT
  end

  def lib_path
    File.join(project_root, "lib")
  end
end
```

**After (broken at runtime):**
```ruby
mixin "my_mixin" do
  def project_root = PROJECT_ROOT
  def lib_path = File.join(project_root, "lib")
end
```

**Error:**
```
undefined local variable or method `project_root' for module #<Module:...> (NameError)
```

**Impact:** Runtime NameError - method references can't resolve in `module_eval` context.

**Tablecop mitigation:** `Style/EndlessMethod` is disabled by default.

---

## 4. Endless Methods with Modifier-if Calling Dynamic Methods

**Cop:** `Style/EndlessMethod`

**Bug:** Endless methods with modifier `if` that reference methods from included/extended modules fail at parse time.

**Before (valid):**
```ruby
class << self
  def clear!
    data_layer.clear! if data_layer.respond_to?(:clear!)
  end
end
```

**After (broken at parse time):**
```ruby
class << self
  def clear! = data_layer.clear! if data_layer.respond_to?(:clear!)
end
```

**Error:**
```
undefined local variable or method `data_layer' for class #<Class:...> (NameError)
```

**Impact:** Parse-time NameError - Ruby tries to resolve the method reference during class definition rather than at call time.

**Tablecop mitigation:** `Style/EndlessMethod` is disabled by default.

---

## 5. Endless Methods with Rescue Clauses

**Cop:** `Style/EndlessMethod`

**Bug:** Converts methods containing `rescue` clauses to endless method syntax, which breaks the code structure entirely since endless methods cannot have rescue clauses.

**Before (valid):**
```ruby
def try
  success(yield)
rescue StandardError => e
  failure(e)
end
```

**After (broken - rescue orphaned, indentation destroyed):**
```ruby
def try = success(yield)
rescue StandardError => e
  failure(e)

  # Everything below is now at wrong indentation and outside the class
  def unwrap!(result)
    ...
  end
```

**Impact:** Critical - orphans rescue clause, destroys all subsequent method indentation, methods end up outside their intended module/class scope.

**Tablecop mitigation:** `Style/EndlessMethod` is disabled by default.

---

## 6. Hash Alignment Infinite Loops

**Cops:** `Layout/HashAlignment` with `table` style + other alignment cops

**Bug:** When `EnforcedHashRocketStyle: table` or `EnforcedColonStyle: table` is combined with other alignment-related cops, autocorrect can enter an infinite loop where cops fight each other.

**Symptoms:**
- `rubocop -a` hangs indefinitely
- CPU spikes to 100%
- Must kill the process

**Tablecop mitigation:** Users should be aware this can happen. If you experience hangs, try:
```yaml
Layout/HashAlignment:
  EnforcedHashRocketStyle: key
  EnforcedColonStyle: key
```

---

## Summary Table

| Bug | Cop | Severity | Detection | Tablecop Default |
|-----|-----|----------|-----------|------------------|
| Heredoc destruction | `Style/EndlessMethod` | Critical (data loss) | Syntax error | Disabled |
| `\|\|=` breaking | `Layout/ExtraSpacing` | Critical | Syntax error | `ForceEqualSignAlignment: false` |
| `module_eval` context | `Style/EndlessMethod` | High | Runtime NameError | Disabled |
| Modifier-if dynamic methods | `Style/EndlessMethod` | High | Parse-time NameError | Disabled |
| Rescue clause destruction | `Style/EndlessMethod` | Critical | Syntax/scope errors | Disabled |
| Alignment infinite loops | `Layout/HashAlignment` | High | Process hangs | Enabled with warning |

---

## Future Work

Tablecop may eventually include wrapper cops that fix these issues by:
- Checking for heredocs/rescue before allowing endless method conversion
- Properly handling compound operators in alignment
- Detecting `module_eval` contexts

For now, the safest approach is to disable the problematic cops or avoid autocorrect on files containing these patterns.

---

*Last updated: 2024-12-10*
*RuboCop version tested: 1.81.7*
