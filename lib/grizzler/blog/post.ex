defmodule Grizzler.Blog.Post do
  use Ash.Resource,
    otp_app: :grizzler,
    domain: Grizzler.Blog,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "posts"
    repo Grizzler.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title, :content, :user_id]
    end

    update :update do
      accept [:title, :content]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :content, :string do
      allow_nil? false
      public? true
    end

    create_timestamp :inserted_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :user, Grizzler.Accounts.User do
      allow_nil? false
      public? true
    end
  end
end
