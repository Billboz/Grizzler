defmodule Grizzler.Blog do
  use Ash.Domain, otp_app: :grizzler, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Grizzler.Blog.Post
  end
end
