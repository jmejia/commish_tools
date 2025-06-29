## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Coding Standards Checklist
- [ ] Business logic is in models (POROs), not controllers
- [ ] Controllers are thin (<10 lines per action)
- [ ] Used domain namespaces where appropriate
- [ ] No service objects or `.call` pattern
- [ ] No new technical pattern directories (`app/services/`, `app/decorators/`, etc.)
- [ ] Class names are nouns, not verbs
- [ ] Tests added/updated for new functionality

## Architecture Review
- [ ] Does this introduce a new domain concept that needs namespacing?
- [ ] Could any controllers be "hidden resources" without AR models?
- [ ] Are we viewing existing resources through new "lenses"?
- [ ] Have we kept the 80% PORO / 20% ActiveRecord target in mind?

## Testing
- [ ] Tests pass locally
- [ ] `bundle exec rake quality` passes
- [ ] Manual testing completed

## Additional Notes
Any additional context, screenshots, or deployment notes. 