# Project-Specific Ash Patterns & Lessons
**Real-world patterns and lessons learned from Grizzler project implementation**

> **Note**: *This content was extracted from scripts/ash_patterns_and_lessons.md and represents project-specific, tested patterns beyond the canonical documentation.*

## Overview

This document captures real, working Ash patterns and lessons learned from the Grizzler project. All examples are version-matched for Ash 3.5.9 and are based on actual, tested code in this codebase.

## Minimal, Working Ash CRUD Patterns

### 1. Create a Task
```elixir
defmodule Grizzler.Tasks.TaskTest do
  # ...
  test "create a task" do
    changeset = Ash.Changeset.for_create(Task, :create, %{title: "Test Task"})
    task = Ash.create!(changeset)
    assert task.title == "Test Task"
  end
end
```

### 2. Read a Task
```elixir
[task] = Task |> Ash.Query.filter(title == "Read Me") |> Ash.read!()
assert task.title == "Read Me"
```

### 3. Update a Task
```elixir
changeset = Ash.Changeset.for_update(task, :update, %{title: "New Title"})
updated_task = Ash.update!(changeset)
assert updated_task.title == "New Title"
```

### 4. Destroy a Task
```elixir
changeset = Ash.Changeset.for_destroy(task, :destroy)
:ok = Ash.destroy!(changeset)
assert Task |> Ash.Query.filter(title == "To Be Deleted") |> Ash.read!() == []
```

## Lessons Learned & Troubleshooting

### Critical Ash Patterns
- **Always use `Ash.Changeset.for_create/3`, `for_update/3`, and `for_destroy/2` for resource actions.**
  - Direct Ecto-style changesets or repo calls will not work with Ash resources.
- **Define all required actions in your resource module.**
  - If you get `undefined function` errors, check that the action (e.g., `:create`, `:update`, `:destroy`) is defined in the `actions do ... end` block.
- **Use `generate?: true` in your domain if you want Ash to generate an API module.**
- **Test CRUD operations early with minimal attributes.**
  - Start with a single required field (e.g., `:title`) and expand only after confirming basic CRUD works.

### Database Management the Ash Way

Ash provides a set of Mix tasks to manage your database schema in a way that is tightly coupled to your Ash resources and migrations. This is the preferred, idiomatic approach for Ash projects.

#### Common Ash DB Tasks

- **Generate Migrations from Resources**
  ```sh
  mix ash_postgres.generate_migrations
  ```
  This inspects your Ash resources and generates Ecto migrations to bring your database schema in sync with your resource definitions.

- **Run Migrations**
  ```sh
  mix ash.migrate
  ```
  Runs all pending migrations for your AshPostgres data layer. Equivalent to `mix ecto.migrate` but Ash-aware.

- **Reset the Database**
  ```sh
  mix ash.reset
  ```
  Drops, creates, and migrates the database in one step, ensuring a clean slate that matches your Ash resources and migrations. (This is the preferred way to reset in development.)

- **Codegen for Resources**
  ```sh
  mix ash.codegen
  ```
  Generates resource and migration files based on your current Ash domain and resource definitions.

#### Best Practices
- Always use `mix ash_postgres.generate_migrations` after changing resource attributes or relationships.
- Use `mix ash.migrate` to apply new migrations.
- Use `mix ash.reset` to drop and recreate the DB from scratch (dev/test only).
- Avoid editing migrations by hand; let Ash generate them from your resource definitions.
- Keep your migrations, resource files, and DB schema in sync to avoid runtime errors.

## Ash Test Setup: Always Use Ash Domains for CRUD

### Critical Lesson
When writing tests (or any code) that creates related records for Ash resources, **always use Ash's API and specify the domain**. Do not use `Repo.insert!` or direct Ecto calls for related records, as Ash will not be aware of them and relationship validation will fail.

This is especially important for join tables and resources with `belongs_to` relationships and `allow_nil?: false` constraints.

### Example: Creating Related Records in Tests (Join Table)

```elixir
defmodule Grizzler.Tasks.UserTaskTest do
  use Grizzler.DataCase, async: true

  alias Grizzler.Tasks.UserTask
  alias Grizzler.Accounts.User
  alias Grizzler.Tasks.Task

  describe "UserTask minimal creation" do
    setup do
      user =
        User
        |> Ash.Changeset.for_create(:create, %{email: "test@example.com"})
        |> Ash.create!(domain: Grizzler.Accounts)

      task =
        Task
        |> Ash.Changeset.for_create(:create, %{
          title: "Test Task",
          description: "A test task",
          duration: 60,
          is_group: false,
          requires_approval: true,
          category: "coding",
          points: 5
        })
        |> Ash.create!(domain: Grizzler.Tasks)

      %{user: user, task: task}
    end

    test "creates a user task association", %{user: user, task: task} do
      user_task =
        UserTask
        |> Ash.Changeset.for_create(:create, %{
          user_id: user.id,
          task_id: task.id
        })
        |> Ash.create!(domain: Grizzler.Tasks)

      assert user_task.user_id == user.id
      assert user_task.task_id == task.id
    end
  end
end
```

## Advanced Patterns from Project Experience

### Attribute Constraints for Validation
- Use attribute-level `constraints: [min: x, max: y]` for numeric ranges (e.g., points).
- Use `constraints: [one_of: [...]]` for enum-like fields (e.g., category).

### Timestamps
- Use `create_timestamp :inserted_at` and `update_timestamp :updated_at` in the attributes block for automatic tracking.

### Required Attributes
- Use `allow_nil?: false` in the attribute definition to enforce required fields.

### Idiomatic Actions
- Use `accept [...]` in actions to whitelist permitted fields for create/update.
- Do not use deprecated or unsupported validation macros; prefer attribute constraints for simple validations.

### General Ash 3.5.9 Lessons
- Place all validations and constraints in the attributes block when possible.
- Use the official docs for version-matched patterns.

## Development Checklist

Follow this checklist whenever developing a new Ash resource in this project. This process is based on real lessons learned and is designed to ensure reliability, maintainability, and rapid troubleshooting.

1. **Start Minimal**
   - Define the resource with only the essential attribute(s) (e.g., `:title`).
   - Implement only the required actions (`:create`, `:read`, `:update`, `:destroy`).
   - Use idiomatic Ash patterns as shown in the examples above.

2. **Test CRUD Operations Early**
   - Write and run tests for create, read, update, and destroy using Ash's changeset and action patterns.
   - Confirm that all basic operations work before expanding the resource.

3. **Expand Attributes and Relationships Gradually**
   - Add new fields, validations, and relationships incrementally.
   - After each change, add or update tests to cover new functionality.

4. **Document Working Patterns and Gotchas**
   - If you encounter a new pattern, workaround, or lesson, update this file.
   - Reference the relevant test or resource file.

5. **Reference Version-Matched Documentation**
   - Always use the official docs and guides for Ash 3.5.9.
   - Prefer patterns that match the project's Ash, Phoenix, and Elixir versions.

6. **Continuous Improvement**
   - Review and update this checklist as new lessons are learned.
   - Update related rules and documentation as needed.

## References

*From original ash_patterns_and_lessons.md:*
- [test/grizzler/tasks/task_test.exs](../test/grizzler/tasks/task_test.exs)
- [lib/grizzler/tasks/task.ex](../lib/grizzler/tasks/task.ex)
- [Ash 3.5.9 Docs](https://hexdocs.pm/ash/3.5.9/)

---

*This file documents project-specific patterns and lessons learned. For foundational Ash patterns, consult the canonical resources in this folder. Update this file as new patterns, issues, or lessons are discovered.*

## Advanced Project-Specific Lessons

### UserTask Resource & Test Patterns (Ash 3.5.9)

From real implementation experience on the Grizzler project:

#### Test Setup & Policies

- **Always define a :create action and permissive policy for test setup**
  ```elixir
  actions do
    create :create do
      accept [:email, :role, ...]
    end
  end
  policies do
    policy action(:create) do
      authorize_if always()
    end
  end
  ```
  *Restrict or remove for production.*

- **Always pass the `actor:` option in Ash action calls**
  ```elixir
  User
  |> Ash.Changeset.for_create(:create, params)
  |> Ash.create(domain: MyApp.Accounts, actor: user)
  ```

#### Policy Action Types vs Custom Actions

- **Use `action_type/1` only for built-in actions; use `action/1` for custom actions**
  ```elixir
  policy action_type([:read, :create, :update, :destroy]) do
    authorize_if always()
  end
  policy action(:approve) do
    authorize_if actor_attribute_equals(:role, :parent)
  end
  ```

#### Code Organization

- **Inline small, resource-specific custom changes/validations at the bottom of the resource file**
  - Refactor to a separate file if reused or grows large.

#### Test Data & Assertions

- **Use `Ash.Seed.seed!` for test data and convert `Ash.CiString` to string in assertions**
  ```elixir
  assert to_string(user.email) == "test@example.com"
  ```

- **Always handle `{:ok, user}` tuples from `Ash.read_one` and similar functions**
  - Pattern match or use a case statement to extract the user struct before making assertions.

#### Reference Pattern

- **Reference canonical sources for all resource, action, and policy patterns**
  - See [ash.md](ash.md) for comprehensive Ash 3.5.9 patterns
  - Check project-specific patterns in this file for real-world gotchas
  - Use version-matched documentation for implementation details 