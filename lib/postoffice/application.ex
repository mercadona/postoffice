defmodule Postoffice.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start PomEx process first to catch all init metrics
      Postoffice.PromEx,
      # Start the Ecto repository
      Postoffice.Repo,
      # Start the endpoint when the application starts
      PostofficeWeb.Endpoint,
      # Starts a worker by calling: Postoffice.Worker.start_link(arg)
      # {Postoffice.Worker, arg},
      {Phoenix.PubSub, [name: Postoffice.PubSub, adapter: Phoenix.PubSub.PG2]},
      {Cluster.Supervisor,
       [Application.get_env(:libcluster, :topologies), [name: Postoffice.ClusterSupervisor]]},
      Postoffice.Rescuer.Producer,
      Postoffice.Rescuer.Supervisor,
      Postoffice.Cache,
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Postoffice.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PostofficeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Conditionally disable crontab, queues, or plugins here.
  defp oban_config do
    Application.get_env(:postoffice, Oban)
  end
end
