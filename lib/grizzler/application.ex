defmodule Grizzler.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GrizzlerWeb.Telemetry,
      Grizzler.Repo,
      {DNSCluster, query: Application.get_env(:grizzler, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:grizzler, :ash_domains),
         Application.fetch_env!(:grizzler, Oban)
       )},
      # Start the Finch HTTP client for sending emails
      # Start a worker by calling: Grizzler.Worker.start_link(arg)
      # {Grizzler.Worker, arg},
      # Start to serve requests, typically the last entry
      {Phoenix.PubSub, name: Grizzler.PubSub},
      {Finch, name: Grizzler.Finch},
      GrizzlerWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :grizzler]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Grizzler.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GrizzlerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
