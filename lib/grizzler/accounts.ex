defmodule Grizzler.Accounts do
  use Ash.Domain, otp_app: :grizzler, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Grizzler.Accounts.Token
    resource Grizzler.Accounts.User
  end
end
