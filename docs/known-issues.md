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

## 2. Heredoc Assignment Alignment Infinite Loop

**Cops:** `Layout/ExtraSpacing` with `ForceEqualSignAlignment: true` + `Layout/SpaceAroundOperators`

**Bug:** When a block of consecutive assignments includes a heredoc, the alignment cops fight each other in an infinite loop.

**Trigger:**
```ruby
spec.summary     = "Short"
spec.description = <<~DESC
  Long description here
DESC
spec.homepage    = "https://example.com"
```

**What happens:**
1. `Layout/ExtraSpacing` tries to align `spec.homepage =` with `spec.description =`
2. `Layout/SpaceAroundOperators` removes extra spaces (only one space around `=`)
3. Repeat forever

**Impact:** `rubocop -a` hangs indefinitely, must kill process.

**Tablecop mitigation:** `ForceEqualSignAlignment` is disabled by default.

**Note:** The `||=` alignment bug previously documented here appears to be fixed in RuboCop 1.81.7.

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

## 6. Hash Alignment Potential Conflicts

**Cops:** `Layout/HashAlignment` with `table` style

**Note:** `Layout/HashAlignment` with `table` style generally works well, but can potentially conflict with other alignment cops in complex scenarios. If you experience hangs with hash-heavy files, try:
```yaml
Layout/HashAlignment:
  EnforcedHashRocketStyle: key
  EnforcedColonStyle: key
```

---

## 7. HashExcept with Mixed Key Types

**Cop:** `Style/HashExcept`

**Bug:** Converts `hash.reject { |k, _| keys.include?(k) }` to `hash.except(*keys)`, but `except` uses strict key equality while `reject` + `include?` handles mixed symbol/string keys.

```ruby
# Before (handles mixed keys correctly):
excluded_keys = [:hash, "hash"]
content = attributes.reject { |k, _| excluded_keys.include?(k) }

# After (BROKEN - :hash and "hash" are different keys to except):
content = attributes.except(*excluded_keys)
```

**Impact:** Subtle data corruption - keys that should be excluded remain when symbol/string mismatch occurs.

**Tablecop mitigation:** `Style/HashExcept` is disabled by default.

---

## 8. DoubleNegation Autocorrect Changes Semantics

**Cop:** `Style/DoubleNegation`

**Bug:** Autocorrects `!!value` to `!value.nil?`, but these have different semantics for `false`:

```ruby
!!false      # => false (correct boolean coercion)
!false.nil?  # => true  (WRONG - false is not nil)
```

**Impact:** Silent logic bugs - program behavior changes without syntax errors.

**Tablecop mitigation:** `Style/DoubleNegation` is disabled by default.

**Note:** RuboCop documentation admits this is "unsafe" but does it anyway.

---

## Summary Table

| Bug | Cop | Severity | Detection | Tablecop Default |
|-----|-----|----------|-----------|------------------|
| Heredoc destruction | `Style/EndlessMethod` | Critical (data loss) | Syntax error | Disabled |
| Heredoc alignment loop | `ExtraSpacing` + `SpaceAroundOperators` | High | Process hangs | `ForceEqualSignAlignment: false` |
| `module_eval` context | `Style/EndlessMethod` | High | Runtime NameError | Disabled |
| Modifier-if dynamic methods | `Style/EndlessMethod` | High | Parse-time NameError | Disabled |
| Rescue clause destruction | `Style/EndlessMethod` | Critical | Syntax/scope errors | Disabled |
| `!!` → `!.nil?` wrong | `Style/DoubleNegation` | Critical (silent bug) | None (logic error) | Disabled |
| Mixed key type handling | `Style/HashExcept` | Medium (data bug) | None (subtle) | Disabled |

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
