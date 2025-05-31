# Ash Framework Resources Index
**Complete resource navigation for Ash 3.5.9 development**

## Entry Point for AI Agents

This directory contains comprehensive, version-matched documentation for Ash Framework 3.5.9 and related libraries. All content is organized by topic and sourced from canonical Ash Core Team documentation, with additional project-specific patterns noted where applicable.

## Core Framework Documentation

### Essential Resources (Always Consult First)
- **[ash.md](ash.md)** - Core concepts, resources, and domains *(canonical)*
- **[ash_postgres.md](ash_postgres.md)** - PostgreSQL data layer integration *(canonical)*
- **[ash_phoenix.md](ash_phoenix.md)** - Phoenix framework integration *(canonical)*

### Specialized Extensions
- **[ash_ai.md](ash_ai.md)** - AI capabilities, vectorization, and LLM tools *(canonical)*
- **[ash_oban.md](ash_oban.md)** - Background job processing with Oban integration *(canonical)*

### Development Tools & Workflow
- **[igniter.md](igniter.md)** - Code generation and project manipulation tools *(canonical)*
- **[testing_tdd.md](testing_tdd.md)** - Comprehensive testing strategies and TDD approach *(canonical + non-canonical patterns)*
- **[authorization_policies.md](authorization_policies.md)** - Authorization patterns using Ash Policy Authorizer *(canonical + non-canonical patterns)*

## Practical Development Guides *(Non-Canonical)*

> **Note**: *The following files contain community-maintained patterns and practical guides extracted from project experience and cheatsheets. Always verify against canonical documentation when in doubt.*

### Core Ash Concepts
- **[ash_domains_resources.md](ash_domains_resources.md)** - Domain and resource modeling patterns *(non-canonical)*
- **[ash_attributes_types.md](ash_attributes_types.md)** - Attribute definitions, types, and constraints *(non-canonical)*
- **[ash_relationships.md](ash_relationships.md)** - Defining and working with relationships *(non-canonical)*
- **[ash_actions.md](ash_actions.md)** - Action patterns and customization *(non-canonical)*

### Advanced Patterns
- **[ash_query_patterns.md](ash_query_patterns.md)** - Advanced querying, filtering, and aggregates *(non-canonical)*
- **[ash_troubleshooting.md](ash_troubleshooting.md)** - Common pitfalls, solutions, and debugging *(non-canonical)*

### Project Management & Tasks
- **[mix_tasks.md](mix_tasks.md)** - Complete mix tasks reference for Ash 3.5.9 *(non-canonical)*
- **[project_patterns.md](project_patterns.md)** - Real-world patterns and lessons from Grizzler project *(non-canonical)*

### Reference Materials
- **[prd.md](prd.md)** - Product Requirements Document template and guidelines

## How to Use This Index

### For AI Coding Assistants
1. **Start with canonical core documentation** (ash.md, ash_postgres.md, ash_phoenix.md)
2. **Reference specialized canonical extensions** as needed for specific features
3. **Consult practical non-canonical guides** for implementation patterns and project-specific lessons
4. **Use specialized topic files** for focused information on specific Ash concepts
5. **Check project_patterns.md** for real-world, tested patterns from this codebase

### Why Specialized Files?

Instead of having one large comprehensive reference file, this directory uses focused, topic-specific files that allow AI agents to:
- **Load only relevant content**: Need TDD info? Load testing_tdd.md (~500 lines) instead of searching through comprehensive documentation
- **Find information faster**: Topic-focused files improve semantic search and content discovery
- **Reduce context pollution**: No unrelated content interfering with specific tasks
- **Scale better**: Each file can grow independently without affecting others

### Content Attribution
- **Canonical Sources**: Files marked as canonical come directly from Ash Core Team documentation
- **Non-Canonical Sources**: Files marked as non-canonical contain:
  - Project-specific patterns and lessons learned
  - Community-maintained references and practical guides  
  - Implementation patterns beyond official documentation
  - Real-world examples from actual codebases

All non-canonical content is clearly marked with attribution and should be verified against official documentation when in doubt.

## Version Compatibility

All resources in this directory are specifically curated for:
- **Ash Framework**: 3.5.9
- **AshPostgres**: Latest compatible version
- **AshPhoenix**: Latest compatible version
- **Phoenix Framework**: As specified in project mix.exs
- **Elixir**: As specified in project mix.exs

---

*This index serves as the primary navigation point for AI agents and developers working with Ash Framework. All paths are relative to this resources directory.* 