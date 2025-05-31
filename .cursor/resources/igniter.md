# Igniter Code Generation Guide
**Intelligent code generation and project manipulation tools**

## Overview

Igniter is a code generation and project patching framework that enables semantic manipulation of Elixir codebases. It provides tools for creating intelligent generators that can both create new files and modify existing ones safely. Igniter works with AST (Abstract Syntax Trees) through Sourceror.Zipper to make precise, context-aware changes to your code.

## Available Modules

### Project-Level Modules (`Igniter.Project.*`)

- **`Igniter.Project.Application`** - Working with Application modules and application configuration
- **`Igniter.Project.Config`** - Modifying Elixir config files (config.exs, runtime.exs, etc.)
- **`Igniter.Project.Deps`** - Managing dependencies declared in mix.exs
- **`Igniter.Project.Formatter`** - Interacting with .formatter.exs files
- **`Igniter.Project.IgniterConfig`** - Managing .igniter.exs configuration files
- **`Igniter.Project.MixProject`** - Updating project configuration in mix.exs
- **`Igniter.Project.Module`** - Creating and managing modules with proper file placement
- **`Igniter.Project.TaskAliases`** - Managing task aliases in mix.exs
- **`Igniter.Project.Test`** - Working with test and test support files

### Code-Level Modules (`Igniter.Code.*`)

- **`Igniter.Code.Common`** - General purpose utilities for working with Sourceror.Zipper
- **`Igniter.Code.Function`** - Working with function definitions and calls
- **`Igniter.Code.Keyword`** - Manipulating keyword lists
- **`Igniter.Code.List`** - Working with lists in AST
- **`Igniter.Code.Map`** - Manipulating maps
- **`Igniter.Code.Module`** - Working with module definitions and usage
- **`Igniter.Code.String`** - Utilities for string literals
- **`Igniter.Code.Tuple`** - Working with tuples

## Basic Usage

### Creating a Simple Generator

```elixir
defmodule MyApp.MixTasks.Gen.MyResource do
  use Igniter.Mix.Task

  @example "mix my_app.gen.my_resource User"
  @shortdoc "Generates a new resource"
  @moduledoc """
  #{@shortdoc}

  ## Example

  ```bash
  #{@example}
  ```
  """

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      positional: [:resource_name],
      schema: [
        with_policy: :boolean
      ],
      defaults: [
        with_policy: false
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter, argv) do
    {%{resource_name: resource_name, with_policy: with_policy?}, _} = 
      positional_args!(argv)

    module_name = Igniter.Code.Module.parse(resource_name)

    igniter
    |> create_resource(module_name)
    |> then(fn igniter ->
      if with_policy? do
        add_policy_authorization(igniter, module_name)
      else
        igniter
      end
    end)
  end

  defp create_resource(igniter, module_name) do
    contents = """
    defmodule #{inspect(module_name)} do
      use Ash.Resource, 
        data_layer: AshPostgres.DataLayer

      attributes do
        uuid_primary_key :id
        attribute :name, :string, public?: true
        timestamps()
      end

      actions do
        defaults [:read, :destroy, create: :*, update: :*]
      end

      postgres do
        table "#{Macro.underscore(module_name) |> String.split(".") |> List.last()}"
        repo MyApp.Repo
      end
    end
    """

    Igniter.Project.Module.create_module(igniter, module_name, contents)
  end

  defp add_policy_authorization(igniter, module_name) do
    Igniter.Code.Module.find_and_update_module!(igniter, module_name, fn zipper ->
      # Add authorization to the use statement
      zipper
      |> Igniter.Code.Function.move_to_function_call_in_current_scope(:use, 2)
      |> case do
        {:ok, zipper} ->
          Igniter.Code.Function.update_nth_argument(zipper, 1, fn zipper ->
            Igniter.Code.Keyword.put_in_keyword(zipper, [:authorizers], [Ash.Policy.Authorizer])
          end)
        :error ->
          zipper
      end
    end)
  end
end
```

### Working with Configurations

```elixir
# Add a dependency
igniter = Igniter.Project.Deps.add_dep(igniter, {:my_dep, "~> 1.0"})

# Update application config
igniter = Igniter.Project.Config.configure(
  igniter, 
  "config.exs", 
  :my_app, 
  [some_key: "some_value"]
)

# Add to application children
igniter = Igniter.Project.Application.add_new_child(
  igniter,
  {MyApp.Worker, []}
)
```

### Modifying Existing Code

```elixir
# Find and update a module
igniter = Igniter.Code.Module.find_and_update_module!(igniter, MyApp.Router, fn zipper ->
  # Add a new route
  Igniter.Code.Common.add_code(zipper, """
  scope "/api" do
    pipe_through :api
    get "/health", HealthController, :show
  end
  """)
end)

# Update a function
igniter = Igniter.Code.Function.move_to_function_call(igniter, :def, 2)
|> case do
  {:ok, zipper} ->
    # Modify the function
    zipper
  :error ->
    # Function not found, create it
    igniter
end
```

## Best Practices

1. **Use proper validation** - Always validate inputs and provide helpful error messages
2. **Make changes atomic** - Group related changes together in a single igniter operation
3. **Provide good documentation** - Include examples and clear descriptions
4. **Test your generators** - Write tests to ensure your generators work correctly
5. **Handle edge cases** - Consider what happens when files already exist or have conflicts

## Common Patterns

### Adding Extensions to Resources

```elixir
defp add_extension(igniter, module_name, extension) do
  Igniter.Code.Module.find_and_update_module!(igniter, module_name, fn zipper ->
    zipper
    |> Igniter.Code.Function.move_to_function_call_in_current_scope(:use, 2)
    |> case do
      {:ok, zipper} ->
        Igniter.Code.Function.update_nth_argument(zipper, 1, fn zipper ->
          Igniter.Code.Keyword.put_in_keyword(zipper, [:extensions], [extension], fn list ->
            [extension | list]
          end)
        end)
      :error ->
        zipper
    end
  end)
end
```

### Creating Test Files

```elixir
defp create_test_file(igniter, module_name) do
  test_module = Module.concat([module_name, Test])
  
  test_contents = """
  defmodule #{inspect(test_module)} do
    use MyApp.DataCase
    
    alias #{inspect(module_name)}
    
    test "creates successfully" do
      # Test implementation
    end
  end
  """
  
  Igniter.Project.Module.create_module(igniter, test_module, test_contents)
end
```

## Error Handling

Igniter provides several mechanisms for handling errors gracefully:

```elixir
# Validate that a module exists
case Igniter.Code.Module.module_exists?(igniter, MyApp.SomeModule) do
  {true, igniter} -> 
    # Module exists, proceed
    igniter
  {false, igniter} ->
    # Module doesn't exist, handle appropriately
    Mix.shell().error("Module MyApp.SomeModule not found")
    igniter
end

# Use find_and_update_module with error handling
case Igniter.Code.Module.find_and_update_module(igniter, module_name, update_fn) do
  {:ok, igniter} -> igniter
  {:error, error} -> 
    Mix.shell().error("Failed to update module: #{inspect(error)}")
    igniter
end
```

---

*This guide covers Igniter usage patterns for code generation and project manipulation. For the latest features and API changes, consult the [official Igniter documentation](https://hexdocs.pm/igniter/).* 