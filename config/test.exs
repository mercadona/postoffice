use Mix.Config

# Configure your database
config :postoffice, Postoffice.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  database: "postoffice_test",
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  port: System.get_env("DB_PORT", "6543") |> String.to_integer(),
  show_sensitive_data_on_connection_error: true,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :postoffice, PostofficeWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :bcrypt_elixir, :log_rounds, 4

config :libcluster,
  topologies: [
    dns_poll_example: [
      strategy: Elixir.Cluster.Strategy.DNSPoll,
      config: [polling_interval: 5_000, query: "my-app.example.com", node_basename: "my-app"]
    ]
  ]

config :postoffice, Oban, crontab: false, queues: false, plugins: false
