# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-10

### Added

- `Tablecop/CondenseWhen` - Condenses multi-line `when` clauses to single lines and aligns `then` keywords
- `Tablecop/AlignMethods` - Aligns contiguous single-line method definitions on the `=` operator
- `Tablecop/AlignAssignments` - Aligns consecutive assignment statements on the `=` operator
- `Tablecop/SafeEndlessMethod` - Converts multi-line methods to endless or traditional one-liner form, avoiding RuboCop's known bugs
- Safe default configuration that disables known-buggy RuboCop cops:
  - `Style/EndlessMethod` (heredoc destruction, rescue orphaning, module_eval failures)
  - `Style/DoubleNegation` (semantically wrong: `!!false` ≠ `!false.nil?`)
  - `Style/HashExcept` (breaks mixed symbol/string key handling)
  - `Layout/ExtraSpacing` with `ForceEqualSignAlignment` (infinite loops with heredocs)
- Documentation of known RuboCop autocorrect bugs in `docs/known-issues.md`
