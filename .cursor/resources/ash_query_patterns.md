# Ash Query Patterns & Aggregates Guide
**Advanced querying, filtering, and aggregate operations**

> **Note**: *This content was extracted from project cheatsheet.md and represents community-maintained patterns beyond the canonical documentation. For canonical guidance, consult [ash.md](ash.md).*

## Overview

Ash's query API (`Ash.Query`) provides composable functions to filter, sort, and manipulate result sets. Here are common query patterns and techniques.

## Basic Queries

```elixir
require Ash.Query

# Filtering a resource
active_users = MyApp.Accounts.User
|> Ash.Query.filter(active == true)
|> Ash.read!(domain: MyApp.Accounts)

# Sorting results
recent_posts = MyApp.Blog.Post
|> Ash.Query.sort(inserted_at: :desc)
|> Ash.read!(domain: MyApp.Blog)

# Pagination (using offset/limit for example)
page1 = MyApp.Blog.Post
|> Ash.Query.page(limit: 10, offset: 0)
|> Ash.read!(domain: MyApp.Blog)
```

- `Ash.Query.filter/2` uses an Elixir DSL for conditions (similar to Ecto's query syntax but within Ash's context).
- `Ash.Query.sort/2` sorts results by a field and direction.
- `Ash.Query.page/2` can apply simple offset/limit pagination (Ash also supports keyset pagination via extensions, not shown here).

## Loading Relationships

Ash can load related data as part of the query (like Ecto's preload):

```elixir
# Load a single relationship (e.g., each post's author)
posts_with_authors = MyApp.Blog.Post
|> Ash.Query.load(:author)
|> Ash.read!(domain: MyApp.Blog)

# Load nested relationships (e.g., post -> author -> profile)
posts_with_profiles = MyApp.Blog.Post
|> Ash.Query.load([author: :profile])
|> Ash.read!(domain: MyApp.Blog)

# Load multiple relationships at once (e.g., author and comments)
posts_complete = MyApp.Blog.Post
|> Ash.Query.load([:author, :comments])
|> Ash.read!(domain: MyApp.Blog)
```

The `load/2` function accepts a single relationship or a nested keyword list to load deeper associations. Under the hood, Ash will optimize queries to fetch the related data efficiently.

## Advanced Filtering

Ash's filtering supports complex logic, including joins on relationships and pattern matching:

```elixir
require Ash.Query
require Ash.Expr

# Complex conditions with boolean logic
one_month_ago = DateTime.add(DateTime.utc_now(), -30, :day)
recent_popular_posts = MyApp.Blog.Post
|> Ash.Query.filter(expr(published == true and inserted_at > ^one_month_ago))
|> Ash.read!(domain: MyApp.Blog)

# Filtering with an existential subquery on a relationship 
# (e.g., users with posts having > 100 likes)
popular_authors = MyApp.Accounts.User
|> Ash.Query.filter(exists(posts, likes > 100))
|> Ash.read!(domain: MyApp.Accounts)

# Text search (ILIKE for case-insensitive search)
search_results = MyApp.Blog.Post
|> Ash.Query.filter(expr(ilike(title, "%elixir%") or ilike(body, "%elixir%")))
|> Ash.read!(domain: MyApp.Blog)
```

- Use the `^` operator to indicate an external variable (e.g., `one_month_ago`).
- `exists(posts, ...)` filters `User` where some related `posts` satisfy the condition (`likes > 100`).
- `ilike` performs a case-insensitive pattern match (assuming Ash translates to the appropriate SQL ILIKE).

## Aggregates and Stats

Ash can compute aggregates via the query or via defined aggregates on the resource:

```elixir
# Count aggregate (get total number of posts)
post_count = MyApp.Blog.Post
|> Ash.Query.aggregate(:count, :id)
|> Ash.read_one!(domain: MyApp.Blog)

# Multiple aggregates in one go (sum, avg, etc., on an Order resource)
stats = MyApp.Sales.Order
|> Ash.Query.aggregate(:sum, :total_price)
|> Ash.Query.aggregate(:avg, :total_price)
|> Ash.Query.aggregate(:max, :total_price)
|> Ash.Query.aggregate(:min, :total_price)
|> Ash.read_one!(domain: MyApp.Sales)
```

In the above, `read_one!` is used because an aggregate query often returns a single result (or nil). The result `stats` might be a map like `%{sum_total_price: 123.45, avg_total_price: 45.67, ...}` depending on how Ash structures the output.

## Calculations

You can define calculations in your resource to compute values from data or relationships. For example:

```elixir
# In your resource definition
calculations do
  calculate :post_count, :integer, expr(count(posts))
  calculate :full_name, :string, expr(first_name <> " " <> last_name)
end
```

This allows you to load and use calculated fields in queries and results:

```elixir
users_with_counts = MyApp.Accounts.User
|> Ash.Query.load([:post_count, :full_name])
|> Ash.read!(domain: MyApp.Accounts)
```

## Query Composition Patterns

### Building Dynamic Queries

```elixir
def search_posts(params) do
  query = MyApp.Blog.Post

  query =
    if params[:search_term] do
      Ash.Query.filter(query, contains(title, ^params[:search_term]))
    else
      query
    end

  query =
    if params[:published_only] do
      Ash.Query.filter(query, published == true)
    else
      query
    end

  query =
    if params[:sort_by] do
      Ash.Query.sort(query, [{params[:sort_by], params[:sort_order] || :asc}])
    else
      query
    end

  Ash.read!(query, domain: MyApp.Blog)
end
```

### Using Query Functions

```elixir
# Define reusable query functions
defmodule MyApp.Blog.PostQueries do
  import Ash.Query

  def published(query \\ MyApp.Blog.Post) do
    filter(query, published == true)
  end

  def by_author(query, author_id) do
    filter(query, author_id == ^author_id)
  end

  def recent(query, days \\ 7) do
    cutoff = DateTime.add(DateTime.utc_now(), -days, :day)
    filter(query, inserted_at > ^cutoff)
  end
end

# Use them composably
recent_published_posts = MyApp.Blog.Post
|> MyApp.Blog.PostQueries.published()
|> MyApp.Blog.PostQueries.recent(30)
|> Ash.read!(domain: MyApp.Blog)
```

## Performance Optimization

### Efficient Loading
```elixir
# Load only needed fields
posts = MyApp.Blog.Post
|> Ash.Query.select([:id, :title, :published_at])
|> Ash.read!(domain: MyApp.Blog)

# Batch load relationships to avoid N+1
posts_with_authors = MyApp.Blog.Post
|> Ash.Query.load(:author)  # Single query for all authors
|> Ash.read!(domain: MyApp.Blog)
```

### Pagination Strategies
```elixir
# Offset-based pagination (simple but less efficient for large datasets)
page = MyApp.Blog.Post
|> Ash.Query.page(limit: 20, offset: 40)
|> Ash.read!(domain: MyApp.Blog)

# Keyset pagination (more efficient for large datasets)
page = MyApp.Blog.Post
|> Ash.Query.sort(:inserted_at)
|> Ash.Query.page(limit: 20, after: last_cursor)
|> Ash.read!(domain: MyApp.Blog)
```

## Best Practices

1. **Always require Ash.Query**: Add `require Ash.Query` at the top of files using query macros
2. **Use expressions for complex logic**: Leverage `expr/1` for complex filter conditions
3. **Compose queries**: Build reusable query functions for common patterns
4. **Load strategically**: Only load relationships and fields you need
5. **Use aggregates wisely**: Prefer database-level aggregates over application-level calculations
6. **Test query performance**: Monitor query execution and optimize as needed

---

*This guide covers query patterns extracted from project experience. For canonical Ash query documentation, consult [ash.md](ash.md) and the [official Ash documentation](https://hexdocs.pm/ash/3.5.9/).* 