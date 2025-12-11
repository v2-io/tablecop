# Tablecop TODO

## Future Improvements

- [ ] Rename gem to `rubocop-tablecop` so it works with RuboCop's plugin system
  - Currently requires `require: tablecop` instead of `plugins: tablecop`
  - Plugin discovery expects `rubocop-*` naming pattern for non-LintRoller gems
  - Would enable `plugins: rubocop-tablecop` in .rubocop.yml
