# Authorization & Policies Guide
**Comprehensive authorization patterns using Ash Policy Authorizer**

## Overview

Ash policies provide a powerful, declarative way to define authorization rules for your resources. Policies define who can perform which actions on your resources, using a flexible condition-based system that integrates seamlessly with Ash's resource-centric architecture.

## Setting Up Policies

### Basic Policy Configuration

To use policies on a resource, add the Ash Policy Authorizer:

```elixir
defmodule MyApp.Tasks.Task do
  use Ash.Resource,
    domain: MyApp.Tasks,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  # ... rest of resource definition
end
```

### Default Policy Behavior

Without explicit policies, Ash denies all access. Always define at least one policy:

```elixir
policies do
  # Allow all actions for admin users
  policy action_type(:*) do
    authorize_if actor_attribute_equals(:role, :admin)
  end

  # Deny everything else
  policy action_type(:*) do
    forbid_if always()
  end
end
```

## Policy Structure

### Basic Policy Syntax

```elixir
policies do
  policy action_type(:read) do
    description "Users can read their own records"
    authorize_if actor_attribute_equals(:id, :user_id)
  end

  policy action([:create, :update]) do
    description "Users can create and update their own tasks"
    authorize_if actor_attribute_equals(:id, :user_id)
  end
end
```

### Policy Conditions

Policies use conditions to determine authorization:

- **`authorize_if`** - Allow if condition is true
- **`forbid_if`** - Deny if condition is true  
- **`authorize_unless`** - Allow if condition is false
- **`forbid_unless`** - Deny if condition is false

## Common Policy Patterns

### Role-Based Authorization

```elixir
policies do
  # Admins can do anything
  policy action_type(:*) do
    authorize_if actor_attribute_equals(:role, :admin)
  end

  # Regular users can read all, but only modify their own
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:role, :user)
  end

  policy action_type([:create, :update, :destroy]) do
    authorize_if expr(actor(:role) == :user and actor(:id) == user_id)
  end
end
```

### Owner-Based Authorization

```elixir
policies do
  # Users can read public tasks or their own tasks
  policy action_type(:read) do
    authorize_if expr(public == true)
    authorize_if actor_attribute_equals(:id, :creator_id)
  end

  # Users can only modify their own tasks
  policy action_type([:update, :destroy]) do
    authorize_if actor_attribute_equals(:id, :creator_id)
  end

  # Users can create tasks (will be assigned as creator)
  policy action_type(:create) do
    authorize_if present(:actor)
  end
end
```

### Tenant-Based Authorization

```elixir
policies do
  # Users can only access records in their tenant
  policy action_type(:*) do
    authorize_if actor_attribute_equals(:tenant_id, :tenant_id)
  end

  # Super admins can access any tenant
  policy action_type(:*) do
    authorize_if actor_attribute_equals(:role, :super_admin)
  end
end
```

## Advanced Policy Conditions

### Using Expressions

```elixir
policies do
  policy action_type(:read) do
    # Complex boolean expressions
    authorize_if expr(
      public == true or 
      (actor(:role) == :manager and department_id == actor(:department_id)) or
      creator_id == actor(:id)
    )
  end
end
```

### Relationship-Based Policies

```elixir
policies do
  # Users can read tasks in projects they're members of
  policy action_type(:read) do
    authorize_if relates_to_actor_via(:project, :members)
  end

  # Team leads can modify tasks in their teams
  policy action_type([:update, :destroy]) do
    authorize_if relates_to_actor_via([:project, :team], :lead)
  end
end
```

### Custom Policy Checks

```elixir
defmodule MyApp.Policies.TaskChecks do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_), do: "user is task assignee or creator"

  @impl true
  def match?(_actor, %{assignee_id: assignee_id, creator_id: creator_id}, options) do
    actor_id = options[:actor_id]
    actor_id == assignee_id || actor_id == creator_id
  end
end

# In your resource
policies do
  policy action_type([:read, :update]) do
    authorize_if {MyApp.Policies.TaskChecks, actor_id: actor(:id)}
  end
end
```

## Action-Specific Policies

### Granular Action Control

```elixir
policies do
  # General read access
  policy action_type(:read) do
    authorize_if always()
  end

  # Specific create action with different rules
  policy action(:create_public_task) do
    authorize_if present(:actor)
  end

  policy action(:create_private_task) do
    authorize_if actor_attribute_equals(:role, :premium_user)
  end

  # Update actions with different constraints
  policy action(:update_title) do
    authorize_if actor_attribute_equals(:id, :creator_id)
  end

  policy action(:update_status) do
    authorize_if expr(
      actor(:id) == creator_id or 
      actor(:id) == assignee_id or
      actor(:role) == :manager
    )
  end
end
```

## Field-Level Authorization

### Sensitive Field Protection

```elixir
policies do
  # Base read access
  policy action_type(:read) do
    authorize_if always()
  end

  # Restrict sensitive fields
  policy action_type(:read) do
    forbid_if accessing_from([:admin_notes, :internal_rating])
    forbid_unless actor_attribute_equals(:role, :admin)
  end
end

# Or use field policies
field_policies do
  field_policy :admin_notes do
    authorize_if actor_attribute_equals(:role, :admin)
  end

  field_policy [:salary, :ssn] do
    authorize_if expr(actor(:id) == id or actor(:role) == :hr)
  end
end
```

## Bypassing Authorization

### Temporary Authorization Bypass

```elixir
# In application code, when you need to bypass policies
# (e.g., for system operations, seeding, etc.)
Task
|> Ash.Changeset.for_create(:create, %{title: "System Task"})
|> Ash.create!(domain: MyApp.Tasks, authorize?: false)

# Or with a specific system actor
system_actor = %{role: :system, id: :system}
Task
|> Ash.Query.filter(archived == true)
|> Ash.destroy_all!(domain: MyApp.Tasks, actor: system_actor)
```

### Context-Based Bypass

```elixir
policies do
  # Allow system operations
  policy action_type(:*) do
    authorize_if context_equals(:operation_type, :system)
  end

  # Regular user policies...
end

# Usage
Task
|> Ash.Changeset.for_create(:create, %{title: "Automated Task"})
|> Ash.create!(
  domain: MyApp.Tasks, 
  actor: user,
  context: %{operation_type: :system}
)
```

## Testing Policies

### Basic Policy Testing

```elixir
defmodule MyApp.TaskPolicyTest do
  use MyApp.DataCase
  require Ash.Query

  alias MyApp.Tasks.Task
  alias MyApp.Accounts.User

  test "users can read their own tasks" do
    user = create_user()
    task = create_task(creator_id: user.id)

    result = 
      Task
      |> Ash.Query.filter(id == ^task.id)
      |> Ash.read(domain: MyApp.Tasks, actor: user)

    assert {:ok, [found_task]} = result
    assert found_task.id == task.id
  end

  test "users cannot read others' private tasks" do
    user = create_user()
    other_user = create_user()
    task = create_task(creator_id: other_user.id, public: false)

    result = 
      Task
      |> Ash.Query.filter(id == ^task.id)
      |> Ash.read(domain: MyApp.Tasks, actor: user)

    assert {:ok, []} = result
  end
end
```

### Using Ash.can? for Policy Testing

```elixir
test "authorization checks with Ash.can?" do
  user = create_user()
  other_user = create_user()
  task = create_task(creator_id: user.id)

  # User can update their own task
  assert Ash.can?({task, :update}, user, domain: MyApp.Tasks)
  
  # Other user cannot update the task
  refute Ash.can?({task, :update}, other_user, domain: MyApp.Tasks)
  
  # Test with specific action
  assert Ash.can?({task, :update_title}, user, domain: MyApp.Tasks)
end
```

### Testing Policy Errors

```elixir
test "raises forbidden error for unauthorized actions" do
  user = create_user()
  other_user = create_user()
  task = create_task(creator_id: other_user.id)

  assert_raise Ash.Error.Forbidden, fn ->
    task
    |> Ash.Changeset.for_update(:update, %{title: "Hacked"})
    |> Ash.update!(domain: MyApp.Tasks, actor: user)
  end
end
```

## Policy Debugging

### Enabling Policy Logging

```elixir
# In config/dev.exs
config :ash, :policies, log_policy_breakdowns: true

# Or per-query
Task
|> Ash.Query.filter(id == ^task_id)
|> Ash.read!(domain: MyApp.Tasks, actor: user, verbose?: true)
```

### Understanding Policy Errors

```elixir
# Policies provide detailed error information
case Task |> Ash.read(domain: MyApp.Tasks, actor: user) do
  {:ok, tasks} -> 
    tasks
  {:error, %Ash.Error.Forbidden{} = error} ->
    # Error contains policy breakdown information
    IO.inspect(error.errors, label: "Policy failures")
    []
end
```

## Performance Considerations

### Efficient Policy Queries

```elixir
policies do
  # Good: Simple attribute comparisons
  policy action_type(:read) do
    authorize_if actor_attribute_equals(:tenant_id, :tenant_id)
  end

  # Less efficient: Complex relationship traversals
  policy action_type(:read) do
    authorize_if relates_to_actor_via([:project, :team, :department], :members)
  end
end
```

### Pre-filtering Data

```elixir
# Use policies to pre-filter data efficiently
policies do
  policy action_type(:read) do
    filter_with expr(
      public == true or 
      creator_id == actor(:id) or
      assignee_id == actor(:id)
    )
  end
end
```

## Best Practices

1. **Start with deny-all** - Use explicit policies rather than implicit allow
2. **Use descriptive names** - Add descriptions to complex policies
3. **Test thoroughly** - Test both success and failure cases
4. **Consider performance** - Use simple conditions when possible
5. **Document complex logic** - Explain business rules in comments
6. **Use expressions wisely** - Balance readability with functionality
7. **Leverage pre-filtering** - Use `filter_with` for efficiency
8. **Handle edge cases** - Consider nil actors and empty results

## Common Patterns

### Multi-level Authorization

```elixir
policies do
  # Organization-level access
  policy action_type(:*) do
    authorize_if relates_to_actor_via(:organization, :members)
  end

  # Project-level access within organization
  policy action_type([:read, :update]) do
    authorize_if relates_to_actor_via(:project, :collaborators)
  end

  # Owner-level access for sensitive operations
  policy action_type(:destroy) do
    authorize_if actor_attribute_equals(:id, :creator_id)
  end
end
```

### Time-based Authorization

```elixir
policies do
  policy action_type(:read) do
    authorize_if expr(
      published_at <= now() and 
      (expires_at is_nil or expires_at > now())
    )
  end
end
```

---

*This guide covers authorization patterns for Ash Framework 3.5.13. For the latest features and API changes, consult the [official Ash Policy documentation](https://hexdocs.pm/ash/3.5.13/policies.html).* 