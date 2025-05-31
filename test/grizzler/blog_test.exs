defmodule Grizzler.BlogTest do
  use Grizzler.DataCase, async: true
  import Grizzler.TestHelpers
  require Ash.Query

  alias Grizzler.Blog

  describe "posts - using Ash.Seed.seed! for fast test data" do
    test "can create a post with valid attributes" do
      user = create_user()

      assert {:ok, post} =
               Blog.Post
               |> Ash.Changeset.for_create(:create, %{
                 title: "My First Blog Post",
                 content: "This is the content of my first blog post.",
                 user_id: user.id
               })
               |> Ash.create()

      assert post.title == "My First Blog Post"
      assert post.content == "This is the content of my first blog post."
      assert post.user_id == user.id
    end

    test "loads user relationship" do
      user = create_user()
      post = create_post(user: user)

      post_with_user = Blog.Post |> Ash.get!(post.id, load: [:user], authorize?: false)

      assert post_with_user.user.id == user.id
      assert to_string(post_with_user.user.email) == to_string(user.email)
    end

    test "can list all posts" do
      user = create_user()
      _post1 = create_post(user: user, title: "First Post")
      _post2 = create_post(user: user, title: "Second Post")

      posts = Blog.Post |> Ash.read!(authorize?: false)

      post_titles = posts |> Enum.map(& &1.title)
      assert "First Post" in post_titles
      assert "Second Post" in post_titles
    end

    test "can update a post" do
      user = create_user()
      post = create_post(user: user)

      {:ok, updated_post} =
        post
        |> Ash.Changeset.for_update(:update, %{title: "Updated Title"})
        |> Ash.update()

      assert updated_post.title == "Updated Title"
    end

    test "can delete a post" do
      user = create_user()
      post = create_post(user: user)

      assert :ok = post |> Ash.destroy()

      assert_raise Ash.Error.Invalid, fn ->
        Blog.Post |> Ash.get!(post.id)
      end
    end
  end

  describe "posts - business logic validation using actions" do
    test "cannot create a post without a title" do
      user = create_user()

      assert {:error, %Ash.Error.Invalid{} = error} =
               Blog.Post
               |> Ash.Changeset.for_create(:create, %{
                 content: "Content without title",
                 user_id: user.id
               })
               |> Ash.create()

      assert error.errors
             |> Enum.any?(&(&1.field == :title))
    end

    test "cannot create a post without content" do
      user = create_user()

      assert {:error, %Ash.Error.Invalid{} = error} =
               Blog.Post
               |> Ash.Changeset.for_create(:create, %{
                 title: "Title without content",
                 user_id: user.id
               })
               |> Ash.create()

      assert error.errors
             |> Enum.any?(&(&1.field == :content))
    end

    test "cannot create a post without a user" do
      assert {:error, %Ash.Error.Invalid{} = error} =
               Blog.Post
               |> Ash.Changeset.for_create(:create, %{
                 title: "Title",
                 content: "Content"
               })
               |> Ash.create()

      assert error.errors
             |> Enum.any?(&(&1.field == :user_id))
    end

    test "validates user exists when creating post" do
      non_existent_user_id = Ash.UUID.generate()

      assert {:error, %Ash.Error.Invalid{} = error} =
               Blog.Post
               |> Ash.Changeset.for_create(:create, %{
                 title: "Title",
                 content: "Content",
                 user_id: non_existent_user_id
               })
               |> Ash.create()

      # Should have a relationship validation error
      assert error.errors
             |> Enum.any?(&(&1.field == :user_id))
    end
  end

  describe "posts - integration scenarios" do
    test "complex blog scenario with multiple users and posts" do
      scenario = create_blog_scenario()

      # Verify the scenario was created correctly
      assert length(scenario.users) == 2
      assert length(scenario.user1_posts) == 2
      assert length(scenario.user2_posts) == 1
      assert length(scenario.all_posts) == 3

      # Test that we can load all posts with their users
      all_posts = Blog.Post |> Ash.Query.load([:user]) |> Ash.read!(authorize?: false)

      assert length(all_posts) >= 3

      # All posts should have loaded users
      Enum.each(all_posts, fn post ->
        refute is_nil(post.user)
        assert is_binary(to_string(post.user.email))
      end)
    end

    test "can filter posts by user" do
      user1 = create_user(email: "user1@test.com")
      user2 = create_user(email: "user2@test.com")

      create_post(user: user1, title: "User 1 Post")
      create_post(user: user2, title: "User 2 Post")

      user1_posts =
        Blog.Post
        |> Ash.Query.filter(user_id: user1.id)
        |> Ash.read!(authorize?: false)

      assert length(user1_posts) == 1
      assert hd(user1_posts).title == "User 1 Post"
    end
  end
end
