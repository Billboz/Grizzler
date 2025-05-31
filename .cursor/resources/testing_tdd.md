# Testing & TDD Guide for Ash Applications
**Comprehensive testing strategies for Ash applications with TDD approach**

## Overview

Testing Ash applications requires understanding how to work with Ash's resource-centric architecture, policies, and domain-driven design. This guide covers testing patterns, TDD workflows, and best practices specific to Ash Framework 3.5.9.

## The Ash Way: Resource-First TDD

Follow this workflow for all Ash resource development:

1. **Start with a test** describing the desired resource/action behavior using Ash idioms
2. **Define or update the resource** (attributes, actions, validations, policies)
3. **Configure the data layer and migrations**
4. **Iterate**: run the test, implement the minimal change to make it pass
5. **Debug and verify** at each step (use IO.inspect, dbg, terminal checks)
6. **Only then, surface to API/UI** and address syntax/style
7. **Update rules and cheatsheets** with new patterns or lessons

### Detailed Development Checklist *(Project-Tested Process)*

Follow this checklist whenever developing a new Ash resource. This process is based on real lessons learned and is designed to ensure reliability, maintainability, and rapid troubleshooting:

1. **Start Minimal**
   - Define the resource with only the essential attribute(s) (e.g., `:title`).
   - Implement only the required actions (`:create`, `:read`, `:update`, `:destroy`).
   - Use idiomatic Ash patterns as shown in the CRUD examples.

2. **Test CRUD Operations Early**
   - Write and run tests for create, read, update, and destroy using Ash's changeset and action patterns.
   - Confirm that all basic operations work before expanding the resource.
   - Reference the basic CRUD patterns in this guide.

3. **Expand Attributes and Relationships Gradually**
   - Add new fields, validations, and relationships incrementally.
   - After each change, add or update tests to cover new functionality.

4. **Document Working Patterns and Gotchas**
   - If you encounter a new pattern, workaround, or lesson, update project documentation.
   - Reference the relevant test or resource file for future reference.

5. **Reference Version-Matched Documentation**
   - Always use the official docs and guides for Ash 3.5.9.
   - Prefer patterns that match the project's Ash, Phoenix, and Elixir versions.

6. **Continuous Improvement**
   - Review and update this checklist as new lessons are learned.
   - Update related rules and documentation as needed.

## Test Setup Essentials

### Always Require Ash.Query and Ash.Expr

In any test file using Ash query macros:

```elixir
defmodule MyApp.MyTest do
  use MyApp.DataCase
  require Ash.Query
  require Ash.Expr  # If using expr/1 macros

  # ... tests
end
```

### Basic Test Structure

```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase
  require Ash.Query

  alias MyApp.Accounts.User

  describe "user creation" do
    test "creates user with valid attributes" do
      params = %{email: "test@example.com", name: "Test User"}
      
      {:ok, user} = 
        User
        |> Ash.Changeset.for_create(:create, params)
        |> Ash.create(domain: MyApp.Accounts)

      assert user.email == "test@example.com"
      assert user.name == "Test User"
    end
  end
end
```

## Resource Testing Patterns

### Testing CRUD Operations

```elixir
defmodule MyApp.Tasks.TaskTest do
  use MyApp.DataCase
  require Ash.Query

  alias MyApp.Tasks.Task

  describe "task CRUD" do
    test "creates a task with valid attributes" do
      params = %{
        title: "Test Task",
        description: "A test task",
        duration: 60
      }

      {:ok, task} = 
        Task
        |> Ash.Changeset.for_create(:create, params)
        |> Ash.create(domain: MyApp.Tasks)

      assert task.title == "Test Task"
      assert task.duration == 60
    end

    test "reads tasks with filters" do
      task = create_task(title: "Important Task")
      
      results = 
        Task
        |> Ash.Query.filter(title == "Important Task")
        |> Ash.read!(domain: MyApp.Tasks)

      assert length(results) == 1
      assert hd(results).id == task.id
    end

    test "updates task attributes" do
      task = create_task(title: "Original")
      
      {:ok, updated} = 
        task
        |> Ash.Changeset.for_update(:update, %{title: "Updated"})
        |> Ash.update(domain: MyApp.Tasks)

      assert updated.title == "Updated"
    end

    test "destroys tasks" do
      task = create_task()
      
      :ok = 
        task
        |> Ash.Changeset.for_destroy(:destroy)
        |> Ash.destroy(domain: MyApp.Tasks)

      assert Task
             |> Ash.Query.filter(id == ^task.id)
             |> Ash.read!(domain: MyApp.Tasks) == []
    end
  end

  # Helper function
  defp create_task(attrs \\ %{}) do
    defaults = %{title: "Test Task", duration: 30}
    params = Map.merge(defaults, attrs)
    
    Task
    |> Ash.Changeset.for_create(:create, params)
    |> Ash.create!(domain: MyApp.Tasks)
  end
end
```

### Testing Relationships

```elixir
defmodule MyApp.RelationshipTest do
  use MyApp.DataCase
  require Ash.Query

  alias MyApp.Accounts.User
  alias MyApp.Tasks.Task

  test "loads related data" do
    user = create_user()
    task = create_task(creator_id: user.id)
    
    loaded_task = 
      Task
      |> Ash.Query.filter(id == ^task.id)
      |> Ash.Query.load(:creator)
      |> Ash.read_one!(domain: MyApp.Tasks)

    assert loaded_task.creator.id == user.id
  end

  test "manages relationships through actions" do
    user = create_user()
    
    {:ok, task} = 
      Task
      |> Ash.Changeset.for_create(:create, %{
        title: "User Task",
        creator_id: user.id
      })
      |> Ash.create(domain: MyApp.Tasks)

    assert task.creator_id == user.id
  end
end
```

## Authorization & Policy Testing

### Testing Policies

```elixir
defmodule MyApp.PolicyTest do
  use MyApp.DataCase
  require Ash.Query

  alias MyApp.Tasks.Task
  alias MyApp.Accounts.User

  describe "task policies" do
    setup do
      admin = create_user(role: :admin)
      regular_user = create_user(role: :user)
      other_user = create_user(role: :user)
      
      task = create_task(creator_id: regular_user.id)
      
      %{
        admin: admin,
        regular_user: regular_user,
        other_user: other_user,
        task: task
      }
    end

    test "admin can read all tasks", %{admin: admin} do
      tasks = 
        Task
        |> Ash.read!(domain: MyApp.Tasks, actor: admin)

      assert length(tasks) > 0
    end

    test "user can read their own tasks", %{regular_user: user, task: task} do
      [found_task] = 
        Task
        |> Ash.Query.filter(id == ^task.id)
        |> Ash.read!(domain: MyApp.Tasks, actor: user)

      assert found_task.id == task.id
    end

    test "user cannot read others' tasks", %{other_user: user, task: task} do
      results = 
        Task
        |> Ash.Query.filter(id == ^task.id)
        |> Ash.read!(domain: MyApp.Tasks, actor: user)

      assert results == []
    end

    test "user can update their own tasks", %{regular_user: user, task: task} do
      {:ok, updated} = 
        task
        |> Ash.Changeset.for_update(:update, %{title: "Updated Title"})
        |> Ash.update(domain: MyApp.Tasks, actor: user)

      assert updated.title == "Updated Title"
    end

    test "user cannot update others' tasks", %{other_user: user, task: task} do
      assert_raise Ash.Error.Forbidden, fn ->
        task
        |> Ash.Changeset.for_update(:update, %{title: "Hacked"})
        |> Ash.update!(domain: MyApp.Tasks, actor: user)
      end
    end
  end
end
```

### Using Ash.can? for Authorization Testing

```elixir
test "authorization checks with Ash.can?" do
  user = create_user()
  other_user = create_user()
  task = create_task(creator_id: user.id)

  # Check if user can update their own task
  assert Ash.can?({task, :update}, user, domain: MyApp.Tasks)
  
  # Check if other user cannot update the task
  refute Ash.can?({task, :update}, other_user, domain: MyApp.Tasks)
end
```

## Testing with Test Data

Ash provides two primary approaches for creating test data, each serving different purposes:

### Understanding Ash.Seed.seed! vs Ash.Generator

#### Ash.Seed.seed! - Database Seeding for Application Data

`Ash.Seed.seed!` is designed for **populating your database** with initial, persistent data that your application needs to function properly.

**Purpose:**
- Set up initial application data (admin users, default categories, system records)
- Populate development and staging environments with baseline data
- Create consistent, known data across environments
- Establish foundation data your application depends on

**Characteristics:**
- Creates **real records** in your database
- Data **persists** between application runs
- Usually run once per environment setup
- Creates **specific, known data** your app depends on
- Bypasses policies and business logic for fast setup

**Example Usage:**
```elixir
# In priv/repo/seeds.exs or seed scripts
defmodule MyApp.Seeds do
  def run do
    # Create admin user that always exists
    Ash.Seed.seed!(MyApp.Accounts.User, %{
      email: "admin@myapp.com",
      role: "admin",
      name: "System Admin"
    })
    
    # Create default categories your app expects
    ["Technology", "Sports", "News"]
    |> Enum.each(fn name ->
      Ash.Seed.seed!(MyApp.Blog.Category, %{
        name: name, 
        slug: String.downcase(name)
      })
    end)
  end
end

# In test helpers for fast test data setup
def create_user(attrs \\ %{}) do
  defaults = %{email: "user#{System.unique_integer()}@test.com"}
  attrs = Map.merge(defaults, attrs)
  Ash.Seed.seed!(MyApp.Accounts.User, attrs)
end
```

#### Ash.Generator - Test Data Generation for Comprehensive Testing

`Ash.Generator` is designed for **generating varied test data** that gets created and destroyed during testing to exercise your application's behavior comprehensively.

**Purpose:**
- Create varied, randomized test data for thorough testing
- Generate data that follows your schema rules and constraints
- Support property-based testing with many different examples
- Test edge cases and validation scenarios

**Characteristics:**
- Creates **temporary data** for individual tests
- Data is **cleaned up** after tests complete
- Generates **random/varied data** each test run
- Used for testing edge cases, validations, and business logic
- Respects resource constraints and generates realistic data

**Example Usage:**
```elixir
# Property-based testing with varied data
defmodule MyApp.UserTest do
  use ExUnit.Case
  use StreamData

  test "user creation with random valid data" do
    # Generates different data each time the test runs
    user_generator = Ash.Generator.for(MyApp.Accounts.User, %{
      email: StreamData.string(:alphanumeric, min_length: 5) 
             |> StreamData.map(&(&1 <> "@test.com")),
      role: StreamData.member_of(["user", "moderator", "admin"]),
      name: StreamData.string(:alphanumeric, min_length: 2)
    })
    
    check all user_attrs <- user_generator do
      assert {:ok, user} = MyApp.Accounts.create_user(user_attrs)
      assert user.email =~ "@test.com"
      assert user.role in ["user", "moderator", "admin"]
    end
  end
end
```

### Key Differences Summary

| Aspect               | Ash.Seed.seed!                        | Ash.Generator                       |
| -------------------- | ------------------------------------- | ----------------------------------- |
| **Purpose**          | Database seeding & fast test setup    | Property-based test data generation |
| **When used**        | App setup/deployment & test helpers   | During comprehensive testing        |
| **Data persistence** | Permanent (seeds) / Temporary (tests) | Temporary                           |
| **Data variety**     | Fixed, specific                       | Random, varied                      |
| **Environment**      | Dev/staging/prod/test                 | Test only                           |
| **Business logic**   | Bypassed for speed                    | Can respect or bypass               |
| **Use case**         | Foundation data & simple test setup   | Edge case testing & validation      |

### Practical Usage Guidelines

#### Use Ash.Seed.seed! when:
- Setting up application foundation data (admin users, categories)
- Creating fast test data where business logic validation isn't needed
- You need the same specific data every time
- Performance is critical (test setup)

#### Use Ash.Generator when:
- Testing with varied, realistic data
- Property-based testing scenarios
- You want to test edge cases and validation rules
- Testing how your application handles different input combinations

### Real-world Implementation Example

```elixir
# Seeds - Run once to set up your application
defmodule MyApp.Seeds do
  def run do
    # This admin always exists - foundation data
    Ash.Seed.seed!(MyApp.Accounts.User, %{
      email: "admin@myapp.com",
      role: "admin",
      name: "System Administrator"
    })
    
    # Default categories your app expects
    Ash.Seed.seed!(MyApp.Blog.Category, %{name: "General", default: true})
  end
end

# Test helpers - Fast setup for most tests
defmodule MyApp.TestHelpers do
  def create_user(attrs \\ %{}) do
    defaults = %{email: "user#{System.unique_integer()}@test.com"}
    attrs = Map.merge(defaults, attrs)
    Ash.Seed.seed!(MyApp.Accounts.User, attrs)
  end
end

# Property-based tests - Comprehensive validation testing
defmodule MyApp.UserValidationTest do
  test "users are created with valid emails across many examples" do
    user_generator = Ash.Generator.for(MyApp.Accounts.User)
    
    check all user_attrs <- user_generator do
      case MyApp.Accounts.create_user(user_attrs) do
        {:ok, user} -> 
          assert String.contains?(user.email, "@")
        {:error, changeset} ->
          # Verify validation errors are appropriate
          assert changeset.errors != []
      end
    end
  end
  
  test "can find the seeded admin user" do
    # This relies on the seeded foundation data existing
    admin = MyApp.Accounts.get_user_by_email!("admin@myapp.com")
    assert admin.role == "admin"
  end
end
```

### Authentication Testing Patterns

For resources using AshAuthentication:

```elixir
defp create_authenticated_user(email) do
  # Request magic link
  User
  |> Ash.Changeset.for_action(:request_magic_link, %{email: email})
  |> Ash.create!(domain: MyApp.Accounts)

  # Generate token (bypassing email delivery)
  token = AshAuthentication.Strategy.MagicLink.Token.generate(
    User, %{email: email}, MyApp.Accounts
  )

  # Sign in with token
  User
  |> Ash.Changeset.for_action(:sign_in_with_magic_link, %{token: token})
  |> Ash.create!(domain: MyApp.Accounts)
end
```

### Testing AshAuthentication Magic Link Strategy *(Project-Specific Pattern)*

When using AshAuthentication's magic link strategy, you cannot use a plain `:create` action to create users. Instead, you must use the `:sign_in_with_magic_link` action, which requires a valid token. In tests, you can generate a token directly using AshAuthentication's helpers.

#### Example: Creating a User with Magic Link in a Test

```elixir
# In your test setup
email = "test@example.com"

# Request a magic link (generates a token, normally sent via email)
:ok =
  User
  |> Ash.Changeset.for_action(:request_magic_link, %{email: email})
  |> Ash.request(domain: Grizzler.Accounts)

# Generate a valid token for the user (bypassing email delivery)
token =
  AshAuthentication.Strategy.MagicLink.Token.generate(
    Grizzler.Accounts.User,
    %{email: email},
    Grizzler.Accounts
  )

# Sign in (or register) the user with the token
{:ok, user} =
  User
  |> Ash.Changeset.for_action(:sign_in_with_magic_link, %{token: token})
  |> Ash.create(domain: Grizzler.Accounts)
```

**Key Points:**
- If you need to do this in multiple tests, extract the logic to a test helper (e.g., `test/support/user_helpers.ex`).
- Always use the Ash API and domain for all user creation in tests.

#### Creating Users for Tests/Seeds: Two Approaches

**Option 1: Use Ash.Seed.seed!/2**
```elixir
user = Ash.Seed.seed!(Grizzler.Accounts.User, %{email: "user@example.com"})
```
- **Pros:** Fast, bypasses policies, great for test/dev.
- **Cons:** Skips business logic, not realistic, no side effects.

**Option 2: Use the Magic Link Flow**
```elixir
magic_link =
  Grizzler.Accounts.User
  |> Ash.ActionInput.for_action(:request_magic_link, %{email: "user@example.com"})
  |> Ash.run!()

token = URI.parse(magic_link) |> # extract token

user =
  Grizzler.Accounts.User
  |> Ash.Changeset.for_create(:sign_in_with_magic_link, %{token: token})
  |> Ash.create!()
```
- **Pros:** Realistic, tests full flow, catches integration issues.
- **Cons:** More complex, slower, can be blocked by policies.

**Choose the approach that fits your test or seed scenario.**

### Critical Testing Principle: Always Use Ash Domains for CRUD

**Never use `Repo.insert!` for Ash resources in tests**

When writing tests (or any code) that creates related records for Ash resources, **always use Ash's API and specify the domain**. Do not use `Repo.insert!` or direct Ecto calls for related records, as Ash will not be aware of them and relationship validation will fail.

This is especially important for join tables and resources with `belongs_to` relationships and `allow_nil?: false` constraints.

#### Example: Creating Related Records in Tests (Join Table)

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
          active: true,
          creator_id: user.id,
          category: :morning,
          points: 10
        })
        |> Ash.create!(domain: Grizzler.Tasks)

      %{user: user, task: task}
    end

    test "creates a UserTask with valid user and task", %{user: user, task: task} do
      params = %{
        user_id: user.id,
        task_id: task.id,
        status: "pending"
      }

      {:ok, user_task} =
        UserTask
        |> Ash.Changeset.for_create(:create, params)
        |> Ash.create(domain: Grizzler.Tasks)

      assert user_task.user_id == user.id
      assert user_task.task_id == task.id
      assert user_task.status == "pending"
    end
  end
end
```

**Why?**
- Ash validates relationships and constraints at the API/domain level, not just the DB level.
- If you use `Repo.insert!`, Ash cannot see the related records and will fail relationship validation.
- Always specify the `domain: ...` option in Ash API calls in tests to ensure the correct context.

## Integration Testing

### Testing with Phoenix Controllers

```elixir
defmodule MyAppWeb.TaskControllerTest do
  use MyAppWeb.ConnCase
  require Ash.Query

  alias MyApp.Tasks.Task

  describe "GET /tasks" do
    test "lists tasks for authenticated user", %{conn: conn} do
      user = create_and_sign_in_user(conn)
      task = create_task(creator_id: user.id)

      conn = get(conn, ~p"/tasks")
      
      assert html_response(conn, 200) =~ task.title
    end
  end

  describe "POST /tasks" do
    test "creates task with valid params", %{conn: conn} do
      user = create_and_sign_in_user(conn)
      
      params = %{task: %{title: "New Task", duration: 60}}
      
      conn = post(conn, ~p"/tasks", params)
      
      assert redirected_to(conn) == ~p"/tasks"
      
      # Verify task was created
      assert Task
             |> Ash.Query.filter(title == "New Task")
             |> Ash.read!(domain: MyApp.Tasks) != []
    end
  end
end
```

### Testing LiveViews

```elixir
defmodule MyAppWeb.TaskLiveTest do
  use MyAppWeb.ConnCase
  import Phoenix.LiveViewTest
  require Ash.Query

  alias MyApp.Tasks.Task

  test "displays tasks", %{conn: conn} do
    user = create_and_sign_in_user(conn)
    task = create_task(creator_id: user.id)

    {:ok, view, html} = live(conn, ~p"/tasks")
    
    assert html =~ task.title
  end

  test "creates task via form", %{conn: conn} do
    user = create_and_sign_in_user(conn)
    
    {:ok, view, _html} = live(conn, ~p"/tasks/new")
    
    view
    |> form("#task-form", task: %{title: "Live Task", duration: 30})
    |> render_submit()
    
    assert_redirected(view, ~p"/tasks")
    
    # Verify task was created
    assert Task
           |> Ash.Query.filter(title == "Live Task")
           |> Ash.read!(domain: MyApp.Tasks) != []
  end
end
```

## Common Testing Patterns

### Testing Validations

```elixir
test "validates required fields" do
  {:error, changeset} = 
    Task
    |> Ash.Changeset.for_create(:create, %{})
    |> Ash.create(domain: MyApp.Tasks)

  assert changeset.errors
         |> Enum.any?(&(&1.field == :title))
end

test "validates field constraints" do
  {:error, changeset} = 
    Task
    |> Ash.Changeset.for_create(:create, %{title: "Task", duration: -1})
    |> Ash.create(domain: MyApp.Tasks)

  assert changeset.errors
         |> Enum.any?(&(&1.field == :duration))
end
```

### Testing Calculations and Aggregates

```elixir
test "loads calculations" do
  user = create_user()
  create_task(creator_id: user.id, duration: 30)
  create_task(creator_id: user.id, duration: 45)

  loaded_user = 
    User
    |> Ash.Query.filter(id == ^user.id)
    |> Ash.Query.load(:total_task_duration)
    |> Ash.read_one!(domain: MyApp.Accounts)

  assert loaded_user.total_task_duration == 75
end
```

## Debugging Tests

### Using Debugging Tools

```elixir
test "debug failing test" do
  user = create_user()
  
  # Use IO.inspect to see data
  user |> IO.inspect(label: "Created user")
  
  # Use dbg for pipeline debugging
  result = 
    Task
    |> Ash.Query.filter(creator_id == ^user.id)
    |> dbg()
    |> Ash.read!(domain: MyApp.Tasks)
    |> dbg()
  
  # Use Tidewave for interactive inspection
  # Tidewave.inspect(result)
end
```

### Common Test Failures and Solutions

1. **Missing domain option**: Always pass `domain: MyApp.Domain` to Ash functions
2. **Authorization errors**: Pass `actor: user` or use `authorize?: false` for test setup
3. **Missing requirements**: Use `require Ash.Query` and `require Ash.Expr`
4. **Policy conflicts**: Create permissive test policies or use `authorize?: false`

## Best Practices

1. **Start with resource tests** before integration tests
2. **Use Ash.Seed.seed!** for simple test data setup
3. **Test both success and failure cases**
4. **Always test with realistic actors and policies**
5. **Use descriptive test names** that explain the behavior
6. **Group related tests** in describe blocks
7. **Extract common setup** into helper functions
8. **Test edge cases and error conditions**

---

*This guide covers testing patterns for Ash Framework 3.5.9. Always consult the [official Ash testing documentation](https://hexdocs.pm/ash/3.5.9/testing.html) for the latest best practices.* 

## Additional Patterns from Project Cheatsheet *(Non-Canonical)*

> **Note**: *The following content was extracted from the project cheatsheet.md and represents community-maintained patterns beyond the canonical documentation.*

### Ash Test & Query Idioms (Canonical Reference)

- **Always require Ash.Query in any test or code file using Ash query macros.**
  - Place `require Ash.Query` at the top, after `use`/`defmodule`.
- **Use `Ash.Query.filter/2` with keyword lists for simple filters.**
  - Example: `Ash.Query.filter(id: user.id)`
- **For more complex expressions, use `expr/1` and require `Ash.Expr`.**
  - Example: `Ash.Query.filter(expr(status == "approved"))`
  - Place `require Ash.Expr` at the top as well.

#### Minimal Working Test Example

```elixir
defmodule MyApp.MyTest do
  use MyApp.DataCase
  require Ash.Query

  test "loads user by id" do
    user = Ash.Seed.seed!(MyApp.Accounts.User, %{email: "test@example.com"})
    query =
      MyApp.Accounts.User
      |> Ash.Query.load(:some_field)
      |> Ash.Query.filter(id: user.id)
    {:ok, loaded_user} = Ash.read_one(query, domain: MyApp.Accounts)
    assert loaded_user.id == user.id
  end
end
```

### Advanced Testing Techniques *(From Project Cheatsheet)*

- **Reference this section for all Ash test/query code.**
- **Use `Ash.Seed.seed!` for fast test data setup when business logic validation isn't required**
- **Prefer `Ash.read_one/2` and `Ash.read!/2` for fetching single/multiple records in tests**
- **Always pass `domain:` and `actor:` options in test scenarios**

### Interactive Debugging in Tests *(From Project Cheatsheet)*

> **Tip:** For advanced, interactive debugging and data inspection, use [Tidewave](https://hexdocs.pm/tidewave/):
> 1. Add `{:tidewave, "~> 0.2"}` to your `mix.exs` deps and run `mix deps.get` (if not already present)
> 2. Start an IEx session: `iex -S mix`
> 3. Call `Tidewave.start()` for a live, interactive dashboard
> 4. Use `Tidewave.inspect(data)` in code or IEx to explore any value
> - Replace `IO.inspect(data)` with `Tidewave.inspect(data)` for better visualization of complex/nested data
> - Use in tests, scripts, and debugging sessions
> - See the [Tidewave Docs](https://hexdocs.pm/tidewave/) for more examples 