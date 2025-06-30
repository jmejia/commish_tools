# Coding Standards & Patterns

## Core Philosophy
We follow Jason Swett's organizational principles for maintainable Rails applications.

## Organization Patterns

### 1. Domain-Based Organization
- **Use namespaces by business domain**, not technical patterns
- Examples: `Billing::`, `Schedule::`, `Reporting::`
- Organize controllers, models, and views within these namespaces

### 2. Models as Abstractions
- **50% POROs, 50% ActiveRecord models** in `app/models`
- Models should abstract reality to make it easier to work with
- POROs go in `app/models` alongside ActiveRecord models
- Models can handle any application logic, not just domain logic

### 3. Hidden Resources Pattern
- Create controllers that don't map to database tables
- Example: `CustomerMessagesController` (no `customer_messages` table)
- Use when you need custom actions beyond RESTful seven

### 4. Multiple Lenses Pattern
- Same resource, different contexts
- Example: `Billing::AppointmentsController` vs `Schedule::AppointmentsController`
- Each handles the same model through different business lenses

## Anti-Patterns to Avoid

### ❌ Service Objects
- Don't create `app/services` directory
- Don't use command pattern with `.call` methods
- Use regular OOP instead

### ❌ Fat Controllers
- Controllers should only handle HTTP concerns
- Move business logic to models (POROs)

### ❌ Organizing by Technical Patterns
- Don't create `app/decorators`, `app/builders`, etc.
- Organize by business meaning instead

## Enforcement Mechanisms

### Code Review Checklist
- [ ] New functionality organized by domain namespace?
- [ ] Business logic in models, not controllers?
- [ ] Using POROs instead of service objects?
- [ ] Controllers thin (< 15 lines per action)?
- [ ] Descriptive class names (nouns, not verbs)?

### Automated Checks
```ruby
# Add to lib/tasks/code_quality.rake
desc "Check for service objects"
task :check_service_objects do
  service_files = Dir.glob("app/services/**/*.rb")
  if service_files.any?
    puts "❌ Service objects found:"
    service_files.each { |f| puts "  #{f}" }
    exit 1
  end
  puts "✅ No service objects found"
end

desc "Check controller line counts"
task :check_controller_size do
  controllers = Dir.glob("app/controllers/**/*.rb")
  controllers.each do |file|
    lines = File.readlines(file)
    method_lines = lines.select { |line| line.strip.start_with?('def ') }
    # Add logic to count lines per method
  end
end
```

### Pre-commit Hooks
```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: check-service-objects
        name: Check for service objects
        entry: bundle exec rake check_service_objects
        language: system
        pass_filenames: false
```

### CI Integration
```yaml
# .github/workflows/code_quality.yml
name: Code Quality
on: [push, pull_request]
jobs:
  standards:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check coding standards
        run: |
          bundle exec rake check_service_objects
          bundle exec rake check_controller_size
```

### Documentation & Examples
- Keep this document updated with examples
- Create architectural decision records (ADRs) when deviating
- Include examples in PR templates

### Team Practices
- Pair programming sessions focused on these patterns
- Regular architecture reviews
- "Pattern of the week" discussions in standups

## Quick Reference

**When creating new functionality:**
1. Which domain does this belong to?
2. Can I use a PORO instead of adding to existing AR model?
3. Does this need a hidden resource controller?
4. Am I keeping controllers thin?

**Red flags in PRs:**
- New `app/services/` files
- Controllers with >15 lines per action  
- Classes named with verbs (`CreateUser` → `UserCreation`)
- Complex logic in controllers instead of models 