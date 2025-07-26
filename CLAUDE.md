# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Core Workflow: Research → Plan → Implement → Validate

**Start every feature with:** "Let me research the codebase and create a plan before implementing."

1. **Research** - Understand existing patterns and architecture
2. **Plan** - Propose approach and verify with you
3. **Implement** - Build with tests and error handling
4. **Validate** - ALWAYS run formatters, linters, and tests after implementation

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
- **Comprehensive testing** - All classes must have corresponding specs except Controllers. No controller tests allowed! Instead, test controllers using feature tests.

This codebase prioritizes maintainability through enforced standards and clear architectural boundaries.
