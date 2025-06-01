# Ash Relationships Guide
**Defining and working with resource relationships**

> **Note**: *This content was extracted from project cheatsheet.md and represents community-maintained patterns beyond the canonical documentation. For canonical guidance, consult [ash.md](ash.md).*

## Overview

Ash resources support defining **relationships** between resources, similar to associations in Ecto. Relationships are declared in a `relationships do ... end` block within a resource. The main types are **belongs_to**, **has_many**, **has_one**, and **many_to_many**.

## Belongs To

A `belongs_to` relationship indicates this resource holds a foreign key pointing to another resource (the *destination*). For example, if each `Ticket` has one `Author` (User), in the `Ticket` resource you would add:

```elixir
relationships do
  belongs_to :author, MyApp.Accounts.User
end
```

This will create an `:author_id` attribute (foreign key) on the `Ticket` resource automatically. By default, Ash infers the foreign key name (`author_id`) from the relationship name, and assumes the source attribute is that foreign key and the destination attribute is the primary key of the related resource. You can override defaults by specifying options like `source_attribute` or `destination_attribute` if the naming convention isn't standard.

## Has Many

A `has_many` is the inverse of a belongs_to: it indicates that many records of this resource relate back to one record of another resource. For example, if a `User` has many `Ticket`(s) as author, in the `User` resource you define:

```elixir
relationships do
  has_many :tickets, MyApp.Support.Ticket
end
```

Ash will assume the `MyApp.Support.Ticket` resource has a foreign key `user_id` (or `author_id` in the above example) pointing to this `User` resource. You can specify the `destination_attribute` explicitly (e.g., `destination_attribute: :author_id`) if the default guess isn't correct. The `has_many` does not create any new DB field by itself; it's based on the foreign key defined by the belongs_to on the other resource.

## Has One

`has_one` is similar to has_many but expects at most one related record. It is typically used when the foreign key on the other resource is unique or when you want to represent a one-to-one relationship. For example, if each `User` has one `Profile` resource, you might put `has_one :profile, MyApp.Accounts.Profile, destination_attribute: :user_id` in `User`. (And `belongs_to :user, MyApp.Accounts.User` in `Profile`).

## Many To Many

Many-to-many relationships in Ash are usually modeled via a join resource. Ash does not use an implicit join table the way Ecto might with `many_to_many` macro; instead, you create a separate resource that represents the join. For example, to relate `Post` and `Tag` with many-to-many, you might have a `PostTag` resource that belongs_to a Post and a Tag, and then in `Post` resource:

```elixir
many_to_many :tags, MyApp.Blog.Tag, 
  through: MyApp.Blog.PostTag, 
  source_attribute_on_join_resource: :post_id, 
  destination_attribute_on_join_resource: :tag_id
```

(The generator does not create many_to_many automatically; you'd define the join resource and relationships manually.)

## Inverse Relationships

When defining relationships, it's common to define both sides (e.g., in `Ticket` define belongs_to `:author`, and in `User` define has_many `:tickets`). The Ash generators can help set this up. For instance, if you used `--relationship belongs_to:author:MyApp.Accounts.User` when generating `Ticket`, it will add the belongs_to to Ticket and may prompt or note to add the inverse has_many to User. Always ensure both ends are configured for completeness. Ash will warn if a resource reference is missing (like a has_many with no corresponding belongs_to) so you can correct it.

## Using Relationships in Code

Once relationships are defined, you can *load* or *manage* them via Ash actions.

### Loading Relationships (Eager Loading)

For loading (eager loading), Ash's read actions can load relationships:

```elixir
# Load a single relationship
tickets_with_authors = 
  MyApp.Support.Ticket 
  |> Ash.Query.load(:author) 
  |> Ash.read!(domain: MyApp.Support)

# Load nested relationships
tickets_with_profiles = 
  MyApp.Support.Ticket 
  |> Ash.Query.load(author: :profile) 
  |> Ash.read!(domain: MyApp.Support)

# Load multiple relationships
tickets_complete = 
  MyApp.Support.Ticket 
  |> Ash.Query.load([:author, :comments]) 
  |> Ash.read!(domain: MyApp.Support)
```

### Managing Relationships

For managing relationships (setting or changing them), Ash provides built-in **changes** like `manage_relationship/3` or you can simply allow the foreign key field to be set in an update action:

```elixir
# Set foreign key directly
ticket 
|> Ash.Changeset.for_update(:assign, %{author_id: user.id})
|> Ash.update!(domain: MyApp.Support)

# Use manage_relationship for more complex scenarios
ticket
|> Ash.Changeset.for_update(:update)
|> Ash.Changeset.manage_relationship(:author, user, type: :replace)
|> Ash.update!(domain: MyApp.Support)
```

## Common Relationship Patterns

### User-Owned Resources
```elixir
# In the owned resource (e.g., Post)
belongs_to :user, MyApp.Accounts.User

# In the User resource
has_many :posts, MyApp.Blog.Post
```

### Self-Referencing Relationships
```elixir
# For parent-child relationships
belongs_to :parent, __MODULE__, source_attribute: :parent_id
has_many :children, __MODULE__, destination_attribute: :parent_id
```

### Polymorphic-style Relationships
```elixir
# Using a join table approach
belongs_to :comment, MyApp.Blog.Comment
belongs_to :commentable_post, MyApp.Blog.Post
belongs_to :commentable_user, MyApp.Accounts.User
```

## Best Practices

1. **Define both sides**: Always define inverse relationships for completeness
2. **Use explicit attributes**: Specify `source_attribute` and `destination_attribute` when naming isn't standard
3. **Prefer join resources**: Use explicit join resources instead of implicit many_to_many for complex scenarios
4. **Load strategically**: Only load relationships you need to avoid N+1 queries
5. **Test relationships**: Verify both loading and setting relationships in tests

---

*This guide covers relationship patterns extracted from project experience. For canonical Ash relationship documentation, consult [ash.md](ash.md) and the [official Ash documentation](https://hexdocs.pm/ash/3.5.13/).* 