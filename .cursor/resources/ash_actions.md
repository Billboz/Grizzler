# Ash Actions Guide
**Defining and customizing resource actions**

> **Note**: *This content was extracted from project cheatsheet.md and represents community-maintained patterns beyond the canonical documentation. For canonical guidance, consult [ash.md](ash.md).*

## Overview

Actions in Ash define what operations can be performed on a resource. By default, a resource can have **read**, **create**, **update**, and **destroy** actions (these correspond to typical CRUD operations). You can also define custom actions (with custom names or specific behaviors). Actions are declared in an `actions do ... end` block in the resource.

## Default Actions

You can quickly include all default CRUD actions by calling:

```elixir
actions do
  defaults [:read, :create, :update, :destroy]
end
```

This will create a basic `:read` action (which fetches records, optionally with filters/sort), a `:create` action (to insert records), `:update` (to modify), and `:destroy` (to delete). These default actions will include all **public** attributes by default for create/update (attributes are considered public if `public?: true` in their definition). You can customize which fields are accepted via the `accept` option or by using the wildcard shorthand as shown in the example above (`create: :*` means "a create action that accepts all public attributes").

## Custom Actions

If you need different behavior, you can define actions individually. For example, you might want a specialized create action called `:register` separate from a normal create, or an update action that performs a specific operation. A custom action definition looks like:

```elixir
actions do
  create :register do
    accept [:email, :password]        # which inputs are accepted
    change MyApp.HashPassword         # a custom change to hash the password
  end

  update :publish do
    accept [:published_at]
    change set_attribute(:published_at, &DateTime.utc_now/0)
  end
end
```

In this snippet, `create :register` defines a custom create action named `register` on the resource, which will only accept `:email` and `:password` fields (ignoring others even if public), and uses a change (`MyApp.HashPassword`) to transform the changeset (for example, hashing the plain password before save). The `update :publish` action only allows setting `:published_at` and uses a built-in change to set that timestamp to now.

## Action Inputs (Accept vs Reject)

By default, Ash create/update actions accept no fields unless specified. Using `accept [...]` within an action explicitly whitelists those attributes for that action. Alternatively, marking attributes as `public?: true` and using the default actions (or `:*` wildcard as shown earlier) will automatically allow them. Conversely, sensitive or internal fields can be left `public?: false` to ensure they cannot be set via external input.

## Calling Actions

To execute an action, you typically build a **changeset** or a **query** and then call the corresponding function.

### Create and Update Actions

For create and update actions, use `Ash.Changeset.for_create/3` or `Ash.Changeset.for_update/4` to construct the changeset, then call `Ash.create!/1` or `Ash.update!/1`. For example, to create a Ticket record:

```elixir
ticket = 
  MyApp.Support.Ticket
  |> Ash.Changeset.for_create(:create, %{subject: "Need help"})
  |> Ash.create!(domain: MyApp.Support)
```

This uses the `:create` action of `Ticket` (which in this case expects a `subject`). The result is a new Ticket record (or an exception if something failed). For update:

```elixir
ticket 
|> Ash.Changeset.for_update(:assign, %{representative_id: rep.id})
|> Ash.update!(domain: MyApp.Support)
```

If you had an update action named `:assign` that accepts a foreign key, you can set a relationship by providing the foreign key value (in this case assigning a Representative to a Ticket by setting `representative_id`).

### Read Actions and Queries

To fetch or query data, you use the `:read` action. You start with the resource module itself (which acts like a queryable) and build an `Ash.Query`:

```elixir
require Ash.Query

results = 
  MyApp.Support.Ticket
  |> Ash.Query.filter(status == :open and contains(subject, "error"))
  |> Ash.Query.sort(:inserted_at)
  |> Ash.read!(domain: MyApp.Support)
```

In this snippet, we required the `Ash.Query` module (to use the `filter` and other query macros). We filtered Tickets where status is open and the subject contains "error", sorted by inserted_at, then executed the query with `Ash.read!()`. The result would be a list of matching Ticket records. Ash's query layer supports quite complex filtering expressions (including and/or logic, pattern matching like `contains/2`, etc.), and these filters will be translated to the underlying data layer (SQL in case of Postgres) automatically.

### Destroy Actions

To delete an entity, use `Ash.destroy!/1`. For example:

```elixir
Ash.destroy!(Ash.Changeset.for_destroy(ticket, :destroy), domain: MyApp.Support)
```

would delete the given `ticket` using the `:destroy` action (assuming the default destroy action is enabled).

## Batch and Transactional Operations

Ash supports running multiple actions in a coordinated way (batches/transactions) via the **Ash.Flow** extension (not covered in detail here) and also supports async execution through its runtime if needed. By default, each `Ash.create!/update!/destroy!` call is its own transaction (in the case of a data layer like Postgres).

You can also use:

```elixir
Ash.transaction(fn ->
  # multiple Ash actions here
end, domain: MyApp.Support)
```

for multi-step operations that must succeed or fail together.

## Do/Don't and Common Mistakes

**Do:**
- Use `accept` to control which fields are settable.
- Use built-in changes for simple logic.
- Always use Ash actions (`Ash.create!`, `Ash.update!`, etc.) instead of direct Repo calls.
- Always pass the `domain:` option in Ash function calls.

**Don't:**
- Don't allow sensitive fields to be public.
- Don't bypass Ash actions with direct Ecto/Repo calls.
- Don't forget to pass `domain:` option.

**Common Mistake:**
Forgetting to specify the `domain:` option in Ash function calls.

**Solution:** Always include `domain: MyApp.YourDomain` in all Ash action calls.

---

*This guide covers action patterns extracted from project experience. For canonical Ash action documentation, consult [ash.md](ash.md) and the [official Ash documentation](https://hexdocs.pm/ash/3.5.13/).* 