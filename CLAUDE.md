# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Workflow: Research → Plan → Implement → Validate

**Start every feature with:** "Let me research the codebase and create a plan before implementing."

1. **Research** - Understand existing patterns and architecture
2. **Plan** - Propose approach and verify with you
3. **Implement** - Build with tests and error handling
4. **Validate** - ALWAYS run formatters, linters, and tests after implementation

## Development Commands

### Core Development
- `bin/dev` - Starts web server, Solid Queue background jobs, and Tailwind CSS compiler
- `bin/rails server` - Start Rails server only (port 3000)
- `bin/rails console` - Rails console
- `bundle install` - Install Ruby dependencies
- `bin/rails db:migrate` - Run database migrations
- `bin/rails db:seed` - Seed database with sample data

### Testing
- `rspec` - Run all tests
- `rspec spec/path/to/test_spec.rb` - Run specific test file
- `rspec spec/path/to/test_spec.rb:LINE_NUMBER` - Run specific test
- `bin/rails test:system` - Run system tests with headless Chrome

### Code Quality & Standards
- `rake coding_standards` - Run comprehensive quality checks (required before commits)
- `bundle exec rubocop` - Ruby linting
- `bundle exec rubocop -a` - Auto-fix Ruby style issues
- `bundle exec brakeman` - Security analysis
- `bin/rails assets:precompile` - Compile assets for production

### Database
- `bin/rails db:create` - Create database
- `bin/rails db:reset` - Drop, create, migrate, and seed database
- `bin/rails db:rollback` - Rollback last migration

## Architecture & Patterns

### Core Philosophy
This codebase follows **Jason Swett's organizational principles** emphasizing:
- **Domain-based organization** over technical layers
- **50% POROs, 50% ActiveRecord models** target for better abstraction
- **Explicit anti-patterns** to avoid Rails pitfalls

### Enforced Standards
The `rake coding_standards` task enforces:
- **No service objects** - Use POROs with clear responsibilities instead
- **Thin controllers** - Max 10 lines per action, delegate to models/POROs
- **No fat models** - Extract business logic to domain objects
- **Comprehensive testing** - All classes must have corresponding specs

### Directory Structure
- `app/models/` - ActiveRecord models and domain POROs
- `app/controllers/` - Thin controllers (heavily regulated)
- `app/views/` - ERB templates with Tailwind CSS
- `spec/` - RSpec tests (1,709+ lines, comprehensive coverage)
- `lib/` - Non-Rails specific Ruby classes
- `config/` - Rails configuration and routes

### Key Integrations
- **Sleeper API** - Fantasy football data integration
- **Google OAuth2** - Authentication via Devise
- **OpenAI API** - AI press conferences and voice cloning
- **Solid Queue** - Database-backed background jobs (no Redis required)

## Technology Stack

### Backend
- **Ruby 3.2.2** with **Rails 8.0.2**
- **PostgreSQL** database
- **Solid Queue** for background jobs (database-backed)
- **Devise + OmniAuth** for authentication

### Frontend
- **Tailwind CSS** for styling
- **Stimulus** controllers for JavaScript behavior
- **Turbo** for SPA-like navigation
- **ERB** templates

### Testing
- **RSpec** with extensive feature/system tests
- **FactoryBot** for test data
- **Capybara + Selenium** for system tests
- **VCR** for API interaction testing

## Environment Setup

### Required Environment Variables
```bash
# Core Rails
RAILS_MASTER_KEY=<provided_in_config/master.key>

# OAuth
GOOGLE_CLIENT_ID=<google_oauth_client_id>
GOOGLE_CLIENT_SECRET=<google_oauth_client_secret>

# API Integrations
SLEEPER_API_BASE_URL=https://api.sleeper.app/v1
OPENAI_API_KEY=<openai_api_key>

# Production
DATABASE_URL=<production_database_url>
```

### Development Setup
1. `bundle install` - Install dependencies
2. `bin/rails db:setup` - Create and seed database
3. Configure Google OAuth credentials
4. `bin/dev` - Start all services

### DevContainer Environment Setup
For GitHub Codespaces or local devcontainers:
1. Copy `.env.devcontainer.example` to `.env.devcontainer`
2. Fill in your environment variables (especially `GITHUB_TOKEN`)
3. Rebuild the devcontainer
4. GitHub CLI will be automatically configured on container start

## Database Schema Overview

### Core Models
- **User** - Devise authentication with Google OAuth2
- **League** - Fantasy leagues with Sleeper integration
- **Team** - Fantasy teams within leagues
- **PressConference** - AI-generated content with voice cloning
- **SuperAdmin** - Administrative user management

### Key Relationships
- Users have many Leagues (as commissioners)
- Leagues have many Teams
- Teams belong to Users and Leagues
- SuperAdmins manage user approval workflows

## Testing Strategy

### Test Categories
- **Model specs** - Unit tests for ActiveRecord models and POROs
- **Controller specs** - HTTP request/response testing
- **Feature specs** - End-to-end user workflows
- **System specs** - Browser-based integration tests

### Testing Best Practices
- Use FactoryBot for consistent test data
- VCR cassettes for external API interactions
- Feature tests cover critical user journeys
- System tests verify JavaScript behavior

### Running Specific Tests
```bash
# All model tests
rspec spec/models/

# Specific feature
rspec spec/features/user_registration_spec.rb

# Single test with line number
rspec spec/models/user_spec.rb:25
```

## Background Jobs

### Solid Queue Configuration
- **Database-backed** job processing (no Redis dependency)
- Jobs run in separate process via `bin/dev`
- Configuration in `config/environments/`

### Common Job Patterns
```ruby
# Enqueue job
SomeJob.perform_later(args)

# Job class structure
class SomeJob < ApplicationJob
  def perform(args)
    # Job logic here
  end
end
```

## Deployment

### Kamal Configuration
- **Docker-based** deployment with Kamal
- Configuration in `config/deploy.yml`
- Commands: `kamal setup`, `kamal deploy`

### Asset Compilation
- Tailwind CSS compiled via `bin/dev` in development
- Production assets via `bin/rails assets:precompile`

## Troubleshooting

### Common Issues
- **Email in development**: Uses letter_opener, emails open in browser
- **Background jobs**: Ensure Solid Queue is running via `bin/dev`
- **OAuth issues**: Verify Google credentials in Rails credentials
- **Asset issues**: Restart `bin/dev` to rebuild Tailwind CSS

### Quality Check Failures
Run `rake coding_standards` to identify specific violations:
- Service object usage (explicitly forbidden)
- Controller action length (max 10 lines)
- Missing test coverage
- Ruby style violations

## Code Examples

### Proper Controller Pattern
```ruby
class LeaguesController < ApplicationController
  def create
    league = League.create_from_sleeper(params)
    redirect_to league_path(league)
  end
end
```

### Domain Object Pattern
```ruby
class SleeperLeagueImporter
  def initialize(league_id)
    @league_id = league_id
  end

  def import
    # Business logic here
  end
end
```

This codebase prioritizes maintainability through enforced standards and clear architectural boundaries.