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

## CodeRabbit PR Review Response Process

When responding to CodeRabbit feedback on pull requests, follow this systematic approach:

### 1. Initial Assessment
- Use `gh pr view [PR_NUMBER] --json comments,reviews` to get overview
- Identify unresolved CodeRabbit comments (those with "Resolve conversation" button visible)
- Create todo list to track responses systematically

### 2. Finding Unresolved Comments
- **Visual inspection**: Check PR files page for "Resolve conversation" buttons
- **API approach**: Use `gh api repos/REPO/pulls/PR/comments` to find comments without replies
- **WebFetch verification**: Fetch PR files page to confirm unresolved status

### 3. Responding to Comments (CRITICAL)
- **NEVER leave general PR comments** - Always respond to specific inline code comments
- **Use nested replies**: Respond directly to CodeRabbit's inline comments in files view
- **Command format**: `gh api repos/REPO/pulls/PR/comments/COMMENT_ID/replies -X POST --field body="RESPONSE"`
- **Verify nesting**: Responses should appear under original comment with proper threading

### 4. Response Strategy
- **Agree**: Implement suggested changes and explain what was done
- **Disagree**: Provide clear reasoning with context about why suggestion doesn't fit
- **Partial agreement**: Acknowledge valid points while explaining constraints
- **Be constructive**: Engage in technical dialogue to reach consensus

### 5. Implementation When Agreeing
- Extract duplicated logic into concerns/modules
- Add proper error handling and validation
- Implement suggested architectural improvements
- Run tests to ensure changes work correctly

### 6. Validation
- Ensure all responses are properly nested under original comments
- Verify comment URLs follow format: `#discussion_r[NUMBER]`
- Check that conversation threads are properly linked
- Run tests and linting after any code changes

### 7. Commit and Push Changes
- **ALWAYS commit code changes** made during CodeRabbit review process
- Use descriptive commit message that references the CodeRabbit feedback addressed
- Include the standard Claude Code footer in commit message
- Push changes to update the PR with implemented improvements
- **Command format**: 
  ```bash
  git add .
  git commit -m "Address CodeRabbit feedback: [brief description]
  
  🤖 Generated with [Claude Code](https://claude.ai/code)
  
  Co-Authored-By: Claude <noreply@anthropic.com>"
  git push
  ```

This process ensures constructive dialogue with CodeRabbit while maintaining high code quality standards and keeping the PR up-to-date with implemented changes.
