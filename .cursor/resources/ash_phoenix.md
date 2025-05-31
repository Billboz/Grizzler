# Ash Phoenix Integration
**Rules for working with AshPhoenix**

## Table of Contents
- [Understanding AshPhoenix](#understanding-ashphoenix)
- [Form Integration](#form-integration)
  - [Creating Forms](#creating-forms)
  - [Code Interfaces](#code-interfaces)
  - [Handling Form Submission](#handling-form-submission)
- [Nested Forms](#nested-forms)
  - [Automatically Inferred Nested Forms](#automatically-inferred-nested-forms)
  - [Adding and Removing Nested Forms](#adding-and-removing-nested-forms)
- [Union Forms](#union-forms)
- [Error Handling](#error-handling)
- [Advanced Form Patterns](#advanced-form-patterns)
- [Best Practices](#best-practices)

---

## Understanding AshPhoenix

AshPhoenix is a package for integrating Ash Framework with Phoenix Framework. It provides tools for integrating with Phoenix forms (`AshPhoenix.Form`), Phoenix LiveViews (`AshPhoenix.LiveView`), and more. AshPhoenix makes it seamless to use Phoenix's powerful UI capabilities with Ash's data management features.

## Form Integration

AshPhoenix provides `AshPhoenix.Form`, a powerful module for creating and handling forms backed by Ash resources.

### Creating Forms

```elixir
# For creating a new resource
form = AshPhoenix.Form.for_create(MyApp.Blog.Post, :create)

# For updating an existing resource
post = MyApp.Blog.get_post!(post_id)
form = AshPhoenix.Form.for_update(post, :update)

# Form with initial value
form = AshPhoenix.Form.for_create(MyApp.Blog.Post, :create,
  params: %{title: "Draft Title"}
)
```

### Code Interfaces

Using the `AshPhoenix` extension in domains gets you special functions in a resource's
code interface called `form_to_*`. Use this whenever possible.

First, add the `AshPhoenix` extension to our domains and resources, like so:

```elixir
use Ash.Domain,
  extensions: [AshPhoenix]
```

which will cause another function to be generated for each definition, beginning with `form_to_`.

For example, if you had the following,
```elixir
# in MyApp.Accounts
resources do
  resource MyApp.Accounts.User do
    define :register_with_password, args: [:email, :password]
  end
end
```

you could then make a form with:

```elixir
MyApp.Accounts.register_with_password(...opts)
```

By default, the `args` option in `define` is ignored when building forms. If you want to have positional arguments, configure that in the `forms` section which is added by the `AshPhoenix` section. For example:

```elixir
forms do
  form :register_with_password, args: [:email]
end
```

Which could then be used as:

```elixir
MyApp.Accounts.register_with_password(email, ...)
```

### Handling Form Submission

In your LiveView:

```elixir
def handle_event("validate", %{"form" => params}, socket) do
  form = AshPhoenix.Form.validate(socket.assigns.form, params)
  {:noreply, assign(socket, :form, form)}
end

def handle_event("submit", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, post} ->
      socket =
        socket
        |> put_flash(:info, "Post created successfully")
        |> push_navigate(to: ~p"/posts/#{post.id}")
      {:noreply, socket}

    {:error, form} ->
      {:noreply, assign(socket, :form, form)}
  end
end
```

## Nested Forms

AshPhoenix supports forms with nested relationships, such as creating or updating related resources in a single form.

### Automatically Inferred Nested Forms

If your action has `manage_relationship`, AshPhoenix automatically infers nested forms:

```elixir
# In your resource:
create :create do
  accept [:name]
  argument :locations, {:array, :map}
  change manage_relationship(:locations, type: :create)
end

# In your template:
<.simple_form for={@form} phx-change="validate" phx-submit="submit">
  <.input field={@form[:name]} />

  <.inputs_for :let={location} field={@form[:locations]}>
    <.input field={location[:name]} />
  </.inputs_for>
</.simple_form>
```

### Adding and Removing Nested Forms

To add a nested form with a button:

```heex
<.button type="button" phx-click="add-form" phx-value-path={@form.name <> "[locations]"}>
  <.icon name="hero-plus" />
</.button>
```

In your LiveView:

```elixir
def handle_event("add-form", %{"path" => path}, socket) do
  form = AshPhoenix.Form.add_form(socket.assigns.form, path)
  {:noreply, assign(socket, :form, form)}
end
```

To remove a nested form:

```heex
<.button type="button" phx-click="remove-form" phx-value-path={location.name}>
  <.icon name="hero-x-mark" />
</.button>
```

```elixir
def handle_event("remove-form", %{"path" => path}, socket) do
  form = AshPhoenix.Form.remove_form(socket.assigns.form, path)
  {:noreply, assign(socket, :form, form)}
end
```

## Union Forms

AshPhoenix supports forms for union types, allowing different inputs based on the selected type.

```heex
<.inputs_for :let={fc} field={@form[:content]}>
  <.input
    field={fc[:_union_type]}
    phx-change="type-changed"
    type="select"
    options={[Normal: "normal", Special: "special"]}
  />

  <%= case fc.params["_union_type"] do %>
    <% "normal" -> %>
      <.input type="text" field={fc[:body]} />
    <% "special" -> %>
      <.input type="text" field={fc[:text]} />
  <% end %>
</.inputs_for>
```

In your LiveView:

```elixir
def handle_event("type-changed", %{"_target" => path} = params, socket) do
  new_type = get_in(params, path)
  path = :lists.droplast(path)

  form =
    socket.assigns.form
    |> AshPhoenix.Form.remove_form(path)
    |> AshPhoenix.Form.add_form(path, params: %{"_union_type" => new_type})

  {:noreply, assign(socket, :form, form)}
end
```

## Error Handling

AshPhoenix provides helpful error handling mechanisms:

```elixir
# In your LiveView
def handle_event("submit", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, post} ->
      # Success path
      {:noreply, success_path(socket, post)}

    {:error, form} ->
      # Show validation errors
      {:noreply, assign(socket, form: form)}
  end
end
```

## Advanced Form Patterns

### Form with Auto-Submit Validation

For real-time validation during user input:

```elixir
def mount(_params, _session, socket) do
  form = AshPhoenix.Form.for_create(MyApp.Accounts.User, :create)
  {:ok, assign(socket, form: form, check_errors: false)}
end

def handle_event("validate", %{"form" => params}, socket) do
  form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: socket.assigns.check_errors)
  {:noreply, assign(socket, form: form, check_errors: true)}
end
```

### Forms with Complex Conditional Logic

For forms that show/hide fields based on user input:

```heex
<.simple_form for={@form} phx-change="validate" phx-submit="submit">
  <.input field={@form[:account_type]} type="select" options={["personal", "business"]} />

  <%= if @form.params["account_type"] == "business" do %>
    <.input field={@form[:company_name]} placeholder="Company Name" />
    <.input field={@form[:tax_id]} placeholder="Tax ID" />
  <% end %>

  <%= if @form.params["account_type"] == "personal" do %>
    <.input field={@form[:first_name]} placeholder="First Name" />
    <.input field={@form[:last_name]} placeholder="Last Name" />
  <% end %>
</.simple_form>
```

### Multi-Step Forms with State Management

For complex wizards that need to maintain state across steps:

```elixir
def mount(_params, _session, socket) do
  form = AshPhoenix.Form.for_create(MyApp.Accounts.User, :create)
  
  socket = 
    socket
    |> assign(form: form, current_step: 1, completed_steps: MapSet.new())
    
  {:ok, socket}
end

def handle_event("next-step", %{"form" => params}, socket) do
  form = AshPhoenix.Form.validate(socket.assigns.form, params, errors: true)
  
  if form.valid? do
    socket =
      socket
      |> assign(form: form, current_step: socket.assigns.current_step + 1)
      |> update(:completed_steps, &MapSet.put(&1, socket.assigns.current_step))
      
    {:noreply, socket}
  else
    {:noreply, assign(socket, form: form)}
  end
end

def handle_event("prev-step", _params, socket) do
  socket = assign(socket, current_step: max(1, socket.assigns.current_step - 1))
  {:noreply, socket}
end
```

### Form Error Recovery Patterns

For graceful handling of submission errors:

```elixir
def handle_event("submit", %{"form" => params}, socket) do
  case AshPhoenix.Form.submit(socket.assigns.form, params: params) do
    {:ok, result} ->
      socket =
        socket
        |> put_flash(:info, "Successfully created!")
        |> push_navigate(to: success_path(result))
        
      {:noreply, socket}

    {:error, %AshPhoenix.Form{} = form} ->
      # Handle validation errors
      {:noreply, assign(socket, form: form)}

    {:error, error} ->
      # Handle unexpected errors
      socket =
        socket
        |> put_flash(:error, "An unexpected error occurred. Please try again.")
        |> assign(form: AshPhoenix.Form.clear_value(socket.assigns.form))
        
      {:noreply, socket}
  end
end
```

### Custom Form Field Components

Create reusable form components for complex inputs:

```elixir
defmodule MyAppWeb.FormComponents do
  use Phoenix.Component
  import AshPhoenix.Form
  
  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, default: []
  attr :label, :string
  
  def rich_select(assigns) do
    ~H"""
    <div class="form-field">
      <.label for={@field.id}><%= @label %></.label>
      <select id={@field.id} name={@field.name} class="custom-select">
        <option value="">Choose an option</option>
        <%= for {label, value} <- @options do %>
          <option value={value} selected={to_string(value) == to_string(@field.value)}>
            <%= label %>
          </option>
        <% end %>
      </select>
      <.error :for={msg <- @field.errors}><%= msg %></.error>
    </div>
    """
  end
end
```

### Form Performance Optimization

For forms with many fields, optimize updates:

```elixir
def handle_event("validate", %{"form" => params, "_target" => target}, socket) do
  # Only validate changed fields for better performance
  form = 
    socket.assigns.form
    |> AshPhoenix.Form.validate(params, errors: false)
    |> maybe_validate_field(target)
    
  {:noreply, assign(socket, form: form)}
end

defp maybe_validate_field(form, [field_name]) when is_binary(field_name) do
  # Custom validation logic for specific fields
  AshPhoenix.Form.validate(form, %{}, errors: [String.to_atom(field_name)])
end

defp maybe_validate_field(form, _), do: form
```

## Best Practices

1. **Let the Resource guide the UI**: Your Ash resource configuration determines a lot about how forms and inputs will work. Well-defined resources with appropriate validations and changes make AshPhoenix more effective.

2. **Leverage code interfaces**: Define code interfaces on your domains for a clean and consistent API to call your resource actions.

3. **Update resources before editing**: When building forms for updating resources, load the resource with all required relationships using `Ash.load!/2` before creating the form.

---

## Related Documentation

- [Ash Framework Core](ash.md) - Core Ash concepts and patterns
- [Ash PostgreSQL](ash_postgres.md) - PostgreSQL data layer
- [Testing & TDD](testing_tdd.md) - Testing strategies for Ash resources
- [Index](index.md) - Complete documentation index 