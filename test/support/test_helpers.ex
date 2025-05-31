defmodule Grizzler.TestHelpers do
  @moduledoc """
  Test helper functions for creating test data efficiently.

  Uses Ash.Seed.seed! for fast test data creation when business logic validation isn't needed.
  Use action-based creation when testing business logic, validations, or side effects.
  """

  alias Grizzler.Accounts
  alias Grizzler.Blog
  require Ash.Query

  @doc """
  Creates a user using Ash.Seed.seed! for fast test data setup.

  Use this when you need a user for testing relationships or other features,
  but don't need to test user creation logic itself.
  """
  def create_user(attrs \\ %{}) do
    defaults = %{email: "user#{System.unique_integer()}@test.com"}

    # Convert keyword list to map if needed
    attrs = if is_list(attrs), do: Enum.into(attrs, %{}), else: attrs
    attrs = Map.merge(defaults, attrs)

    Ash.Seed.seed!(Accounts.User, attrs)
  end

  @doc """
  Creates a post using Ash.Seed.seed! for fast test data setup.

  Use this when you need a post for testing other features,
  but don't need to test post creation logic itself.
  """
  def create_post(attrs \\ %{}) do
    # Convert keyword list to map if needed
    attrs = if is_list(attrs), do: Enum.into(attrs, %{}), else: attrs

    user = attrs[:user] || create_user()

    defaults = %{
      title: "Test Post #{System.unique_integer()}",
      content: "Test content for post #{System.unique_integer()}",
      user_id: user.id
    }

    # Remove :user key before passing to Ash.Seed.seed!
    attrs = attrs |> Map.delete(:user) |> then(&Map.merge(defaults, &1))

    Ash.Seed.seed!(Blog.Post, attrs)
  end

  @doc """
  Creates a post through the actual create action.

  Use this when testing post creation logic, validations, or side effects.
  """
  def create_post_via_action(attrs \\ %{}) do
    # Convert keyword list to map if needed
    attrs = if is_list(attrs), do: Enum.into(attrs, %{}), else: attrs

    user = attrs[:user] || create_user()

    defaults = %{
      title: "Post via Action #{System.unique_integer()}",
      content: "Content created via action",
      user_id: user.id
    }

    attrs = attrs |> Map.delete(:user) |> then(&Map.merge(defaults, &1))

    {:ok, post} =
      Blog.Post
      |> Ash.Changeset.for_create(:create, attrs)
      |> Ash.create(domain: Blog)

    post
  end

  @doc """
  Creates multiple users for testing scenarios with multiple actors.
  """
  def create_users(count \\ 3) do
    Enum.map(1..count, fn i ->
      create_user(%{email: "user#{i}#{System.unique_integer()}@test.com"})
    end)
  end

  @doc """
  Creates multiple posts for a user.
  """
  def create_posts_for_user(user, count \\ 3) do
    Enum.map(1..count, fn i ->
      create_post(%{
        user: user,
        title: "Post #{i} for #{user.email}",
        content: "Content for post #{i}"
      })
    end)
  end

  @doc """
  Creates a complete blog scenario with users and posts for integration testing.
  """
  def create_blog_scenario do
    users = create_users(2)
    [user1, user2] = users

    user1_posts = create_posts_for_user(user1, 2)
    user2_posts = create_posts_for_user(user2, 1)

    %{
      users: users,
      user1: user1,
      user2: user2,
      user1_posts: user1_posts,
      user2_posts: user2_posts,
      all_posts: user1_posts ++ user2_posts
    }
  end
end
