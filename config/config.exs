# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :postoffice, Postoffice.PromEx,
  manual_metrics_start_delay: :no_delay,
  drop_metrics_groups: [],
  grafana: :disabled,
  metrics_server: :disabled

config :postoffice,
  ecto_repos: [Postoffice.Repo],
  pubsub_project_name: System.get_env("GCLOUD_PUBSUB_PROJECT_ID", "test")

config :postoffice, PostofficeWeb.Endpoint,
  http: [port: 4000],
  secret_key_base: "ltXgZliDmN0mLNWAF5iobiRF6G3q96oWvttpWlqb1hahcxgAwcxOGG9R5khNiWy5",
  render_errors: [view: PostofficeWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Postoffice.PubSub,
  root: ".",
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine

config :libcluster,
  topologies: []

config :postoffice, Oban,
  repo: Postoffice.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: System.get_env("OBAN_PRUNER_MAX_AGE", 60)}
  ],
  queues: [default: 10, http: 100, pubsub: 15]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
