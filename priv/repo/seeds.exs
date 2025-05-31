# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This file uses Ash.Seed.seed! to populate your database with initial application data.
# Unlike test data, seed data persists between application runs and provides
# foundation data your application depends on.

alias Grizzler.Accounts
alias Grizzler.Blog

# Create an admin user for system administration
admin_user =
  Ash.Seed.seed!(Accounts.User, %{
    email: "admin@grizzler.local"
  })

IO.puts("✅ Created admin user: #{admin_user.email}")

# Create some sample blog posts for development
sample_posts = [
  %{
    title: "Welcome to Grizzler",
    content: """
    Welcome to Grizzler! This is a sample blog post created during database seeding.

    This application demonstrates Ash Framework patterns for building modern Elixir applications.
    """,
    user_id: admin_user.id
  },
  %{
    title: "Getting Started with Ash Framework",
    content: """
    Ash Framework provides a powerful toolkit for building robust applications in Elixir.

    Key features include:
    - Declarative resource definitions
    - Built-in authorization and policies
    - GraphQL and JSON:API support
    - Powerful query capabilities
    """,
    user_id: admin_user.id
  }
]

Enum.each(sample_posts, fn post_attrs ->
  post = Ash.Seed.seed!(Blog.Post, post_attrs)
  IO.puts("✅ Created blog post: #{post.title}")
end)

IO.puts("\n🎉 Database seeding completed successfully!")
IO.puts("   You can now start the application with sample data.")
