# Ash Attributes & Types Guide
**Attribute definitions, types, and constraints for Ash resources**

> **Note**: *This content was extracted from project cheatsheet.md and represents community-maintained patterns beyond the canonical documentation. For canonical guidance, consult [ash.md](ash.md).*

## Overview

Resource **attributes** define the fields of your data model. You declare attributes inside an `attributes do ... end` block in the resource.

## Primitive Types

Ash supports common scalar types such as `:string`, `:integer`, `:boolean`, `:decimal`, `:date`, `:utc_datetime`, `:atom`, etc. For example:

```elixir
attribute :name, :string
```

defines a string field called `name`. You can specify options like `allow_nil? false` to mark an attribute as required (non-null), and `public? true` to mark it as part of the resource's public interface (meaning it can be set via create/update actions).

## Primary Keys

You can use convenience macros for primary keys. For example:

```elixir
uuid_primary_key :id
```

creates a UUID v4 primary key field named `id`. Alternatively, `integer_primary_key :id` would use an integer. By default, these are non-null and unique. There are also options for UUID v7 if needed.

## Timestamps

Ash provides macros for timestamp fields:

```elixir
create_timestamp :inserted_at
update_timestamp :updated_at
```

will automatically write the current time when a record is inserted or updated, respectively. You can also manually add typical timestamp fields with `attribute :inserted_at, :utc_datetime` etc., but using the macros ensures consistent behavior (and migration defaults like `now()`).

## Constraints and Defaults

Attributes can have **constraints** and **default values**. Constraints further restrict valid values (e.g., a string's max length, an integer's range, etc., depending on type). For example, for an `:integer` you might specify:

```elixir
attribute :points, :integer, allow_nil?: false, default: 0, constraints: [min: 0]
```

to require a non-negative integer defaulting to 0. Ash uses these constraints for validation and for generating database constraints (like check constraints) when using AshPostgres. Default values can be static or computed (e.g., `default: &MyModule.default_fun/0` for a dynamic default).

## Enumerations

For a fixed set of values, consider using an enum type. You can generate an Ash enum type module with:

```bash
mix ash.gen.enum MyApp.Types.StatusType active,inactive,archived
```

which creates a module implementing `Ash.Type` for those values. In a resource, you'd use it as:

```elixir
attribute :status, MyApp.Types.StatusType
```

Alternatively, use built-in `:atom` type with constraints allowing only certain atoms, but a custom enum type gives nicer error messages. Use `mix ash.gen.enum` for such scenarios.

## Common Attribute Patterns

### Required String Fields
```elixir
attribute :email, :string, allow_nil?: false, public?: true
```

### Optional Fields with Defaults
```elixir
attribute :active, :boolean, default: true, public?: true
```

### Constrained Integers
```elixir
attribute :age, :integer, constraints: [min: 0, max: 150], public?: true
```

### Enum-style Attributes
```elixir
attribute :status, :atom, constraints: [one_of: [:draft, :published, :archived]], public?: true
```

### Decimal with Precision
```elixir
attribute :price, :decimal, constraints: [precision: 10, scale: 2], public?: true
```

## Best Practices

1. **Mark public attributes**: Use `public?: true` for fields that should be settable via actions
2. **Use constraints**: Define validation rules at the attribute level when possible
3. **Prefer enums**: Use custom enum types for fixed sets of values
4. **Use timestamps**: Leverage `create_timestamp` and `update_timestamp` macros
5. **Set defaults**: Provide sensible defaults for optional fields
6. **Validate at the edge**: Use `allow_nil?: false` for required fields

---

*This guide covers attribute and type patterns extracted from project experience. For canonical Ash attribute documentation, consult [ash.md](ash.md) and the [official Ash documentation](https://hexdocs.pm/ash/3.5.13/).* 