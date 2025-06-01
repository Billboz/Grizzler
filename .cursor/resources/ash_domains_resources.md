# Ash Domains & Resources Guide
**Resource modeling and domain organization patterns**

> **Note**: *This content was extracted from project cheatsheet.md and represents community-maintained patterns beyond the canonical documentation. For canonical guidance, consult [ash.md](ash.md).*

## Overview

Ash applications revolve around defining **resources** and grouping them into **domains**. A **resource** defines a data model (like an entity or table) along with its attributes, relationships, and actions. A **domain** is a module that groups related resources (similar to a context or API module) and can apply common extensions or configuration.

## Generating a Domain

Use `mix ash.gen.domain MyApp.DomainName` to create a new domain module. The domain module will use `Ash.Domain` and serve as a container for resources. For example:

```bash
mix ash.gen.domain MyApp.Accounts
```

This will generate an `Accounts` domain module for grouping user/account resources.

## Generating a Resource

Use `mix ash.gen.resource` to generate a new resource within a domain. This will create a resource module with the given name and update the domain to include it. For example:

```bash
mix ash.gen.resource MyApp.Support.Ticket \
  --default-actions read,create,update,destroy \
  --uuid-primary-key id \
  --attribute subject:string:required:public \
  --relationship belongs_to:representative:MyApp.Support.Representative \
  --timestamps \
  --extend postgres
```

The above command would generate a `Ticket` resource in the `MyApp.Support` domain with a UUID primary key named `id`, a required string attribute `subject` (marked public), a `belongs_to` relationship to a `Representative` resource, timestamp fields, and extending the resource with the Postgres data layer. The generator also adds the new resource to the domain's resource list. If the domain module didn't exist, it will be created automatically.

## Resource Structure

Each resource is an Elixir module that uses `Ash.Resource`. In Ash 3.5, you typically specify the domain and data layer in the `use` line or via extensions. For example, a resource might look like:

```elixir
defmodule MyApp.Posts.Post do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    domain: MyApp.Posts

  # Postgres data layer configuration
  postgres do
    table "posts"
    repo MyApp.Repo
  end

  actions do
    # Provide default read and destroy actions, and basic create/update actions
    defaults [:read, :destroy, create: :*, update: :*]
  end

  attributes do
    uuid_primary_key :id                 # UUID primary key
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :body, :string, allow_nil?: false, public?: true
    create_timestamp :inserted_at        # auto set on creation
    update_timestamp :updated_at        # auto set on updates
  end

  # (relationships, validations, etc. would go here)
end
```

In the above example, the `use Ash.Resource` line declares that this module is an Ash resource, sets the data layer to AshPostgres (meaning this resource's data is stored in a Postgres table), and associates it with the `MyApp.Posts` domain. The `postgres ... end` block configures the table name and Ecto repo for the Postgres data layer. We define default actions (read, destroy, etc.) and a set of attributes including a UUID primary key and timestamp fields. Public attributes (marked `public?: true`) are allowed to be set via external input; setting `allow_nil?: false` on an attribute enforces NOT NULL at the database and validation level.

## Domain Module Structure

Domain modules use `Ash.Domain` and list resources. For example, if you have a domain `MyApp.Posts`, it might look like:

```elixir
defmodule MyApp.Posts do
  use Ash.Domain

  resources do
    resource MyApp.Posts.Post
    resource MyApp.Posts.Comment
    # ... other resources
  end
end
```

Whenever you generate a resource with a domain, the generator will add a `resource ...` entry in the domain. Ensuring the domain lists all its resources is important; Ash performs compile-time checks and needs the domain to reference the resource for things like code generation. (If you forget to add a resource to a domain or to define the expected relationship, Ash will raise helpful compile-time errors.)

## Configuration

In your app's config (e.g., `config/config.exs`), list all domain modules under the `:ash_domains` key so Ash can discover them. For example:

```elixir
config :my_app, :ash_domains, [MyApp.Accounts, MyApp.Posts]
```

This allows Ash's tasks (like code generation and migrations) to find all resources in your application.

---

*This guide covers domain and resource patterns extracted from project experience. For canonical Ash domain and resource documentation, consult [ash.md](ash.md) and the [official Ash documentation](https://hexdocs.pm/ash/3.5.13/).* 