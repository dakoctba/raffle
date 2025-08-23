defmodule RaffleApi.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RaffleApiWeb.Telemetry,
      RaffleApi.Repo,
      {DNSCluster, query: Application.get_env(:raffle_api, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RaffleApi.PubSub},
      # Start a worker by calling: RaffleApi.Worker.start_link(arg)
      # {RaffleApi.Worker, arg},
      # Start to serve requests, typically the last entry
      {Task.Supervisor, name: RaffleApi.UserBufferSupervisor},
      RaffleApi.Users.UserBuffer,
      RaffleApiWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RaffleApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RaffleApiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
