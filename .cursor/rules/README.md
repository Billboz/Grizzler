# Cursor AI Rules & Navigation

This document serves as the **primary entry point** for AI coding assistants working in this Elixir/Phoenix/Ash project. It provides a clear flow for finding the right rules and resources at any stage of development.

## Quick Start for AI Assistants

### 1. **First Contact** - Understanding the Project
- **Start here:** [dev_workflow.mdc](dev_workflow.mdc) - Task Master workflow and development process
- **Project context:** [project_overview.mdc](project_overview.mdc) - High-level project understanding  

### 2. **Implementation Flow** - Following "The Ash Way"
- **Test-driven development:** [ash_dev_flow.mdc](ash_dev_flow.mdc) - Resource-first TDD approach
- **Ash patterns:** [ash_patterns.mdc](ash_patterns.mdc) - Query macros and common patterns

### 3. **Problem Solving**
- **Debugging:** [debugging.mdc](debugging.mdc) - Elixir debugging tools (IO.inspect, dbg, Tidewave)
- **Documentation:** [documentation_usage.mdc](documentation_usage.mdc) - Version-matched official docs
- **Task management:** [taskmaster.mdc](taskmaster.mdc) - Complete Task Master reference

### 4. **Continuous Improvement**
- **Rule updates:** [self_improve.mdc](self_improve.mdc) - Git-integrated rule improvement workflow

## Rule Activation Strategy

### Always Active Rules (`alwaysApply: true`)
These rules are automatically applied and guide every interaction:
- `dev_workflow.mdc` - Core development workflow
- `ash_dev_flow.mdc` - Ash-specific TDD flow
- `ash_patterns.mdc` - Essential Ash patterns and query macros
- `documentation_usage.mdc` - Version-matched documentation usage
- `self_improve.mdc` - Continuous rule improvement

### Context-Specific Rules (`alwaysApply: false`)
These provide specialized guidance when needed:
- `project_overview.mdc` - High-level project context
- `debugging.mdc` - Troubleshooting toolkit

## AI Assistant Decision Tree

```
Start New Work Session
    ↓
Check Task Master status (dev_workflow.mdc)
    ↓
Implementing Ash Resource?
    ↓ YES                           ↓ NO
Follow ash_dev_flow.mdc         Follow standard dev_workflow.mdc
(with ash_patterns.mdc always available)
    ↓                               ↓
Debugging Needed?                Debugging Needed?
    ↓ YES                           ↓ YES
Use debugging.mdc               Use debugging.mdc
    ↓                               ↓
Update Rules?                   Update Rules?
    ↓ YES                           ↓ YES
Follow self_improve.mdc         Follow self_improve.mdc
```

## How It All Works Together

### For New Feature Development:
1. AI follows `dev_workflow.mdc` → starts with Task Master
2. For Ash resources → follows `ash_dev_flow.mdc` TDD approach
3. Uses `ash_patterns.mdc` for patterns
4. Uses `debugging.mdc` when issues arise
5. Updates rules via `self_improve.mdc` when new patterns emerge

### For Debugging/Problem Solving:
1. AI consults `debugging.mdc` for tool recommendations
2. References `documentation_usage.mdc` for version-matched docs
3. Updates patterns if new solutions emerge

### For Maintenance/Improvement:
1. AI follows `self_improve.mdc` triggers
2. Cross-references `cursor_rules.mdc` for proper formatting
3. Maintains coherence across the entire system

---

**Key Insight:** The rules provide **workflow and decision guidance**, creating a comprehensive, self-improving development environment that gets smarter with each interaction. 