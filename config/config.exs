# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :postoffice,
  ecto_repos: [Postoffice.Repo],
  pubsub_project_name: System.get_env("GCLOUD_PUBSUB_PROJECT_ID", "test")

config :postoffice, PostofficeWeb.Endpoint,
  http: [port: 4000],
  secret_key_base: "ltXgZliDmN0mLNWAF5iobiRF6G3q96oWvttpWlqb1hahcxgAwcxOGG9R5khNiWy5",
  render_errors: [view: PostofficeWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Postoffice.PubSub, adapter: Phoenix.PubSub.PG2],
  root: ".",
  instrumenters: [PostofficeWeb.Metrics.Phoenix]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason
config :phoenix, :template_engines, leex: Phoenix.LiveView.Engine

config :goth,
  json: System.get_env("GCLOUD_PUBSUB_CREDENTIALS_PATH", "/secrets/dummy-credentials.json") |> File.read!()

config :libcluster,
  topologies: []

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
