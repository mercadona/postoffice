defmodule Postoffice.MixProject do
  use Mix.Project

  def project do
    [
      app: :postoffice,
      version: "0.19.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      include_erts: true,
      releases: [
        postoffice: [
          config_providers: [{ConfigTuples.Provider, ""}]
        ]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Postoffice.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :httpoison,
        :os_mon,
        :cachex
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.8"}, # https://hexdocs.pm/phoenix/Phoenix.html --> 1.16.15
      {:phoenix_pubsub, "~> 2.0"}, # https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html --> 2.1.1
      {:phoenix_ecto, "~> 4.2"}, # https://hexdocs.pm/phoenix_ecto/Phoenix.Ecto.html --> 4.4.0
      {:ecto_sql, "~> 3.6.1"}, # https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.html --> 3.9.0
      {:postgrex, ">= 0.0.0"}, # https://hexdocs.pm/postgrex/Postgrex.html --> 0.16.0
      {:phoenix_html, "~> 2.14.1"}, # https://hexdocs.pm/phoenix_html/Phoenix.HTML.html --> 3.2.0
      {:phoenix_live_reload, "~> 1.3", only: :dev}, # https://hexdocs.pm/phoenix_live_reload/Phoenix.LiveReloader.html -> 1.4
      {:gettext, "~> 0.18.2"}, # https://hexdocs.pm/gettext/Gettext.html -> 0.20.0
      {:jason, "~> 1.0"}, # https://hexdocs.pm/jason/readme.html --> 1.4.0
      {:plug_cowboy, "~> 2.0"}, # https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html --> 2.6.0
      {:bcrypt_elixir, "~> 2.3"}, # https://hexdocs.pm/bcrypt_elixir/Bcrypt.html --> 3.0.1
      {:google_api_pub_sub, "~> 0.28.1"}, # https://hexdocs.pm/google_api_pub_sub/0.36.0/api-reference.html --> 0.36.0
      {:goth, "~> 1.1.0"}, # https://hexdocs.pm/goth/api-reference.html -> 1.3.1
      {:httpoison, "~> 1.8"}, # https://hexdocs.pm/httpoison/HTTPoison.html -> 1.8.2
      {:mox, "~> 0.5", only: :test}, # https://hexdocs.pm/mox/Mox.html -> 1.0.2
      {:gen_stage, "~> 0.14"}, # https://hexdocs.pm/gen_stage/GenStage.html -> 1.1.2
      {:ink, "~> 1.0"}, # https://hexdocs.pm/ink/readme.html -> 1.2.1
      {:config_tuples, "~> 0.4"}, # https://hexdocs.pm/config_tuples/ConfigTuples.Provider.html -> 0.4.2
      {:libcluster, "~> 3.2"}, # https://hexdocs.pm/libcluster/readme.html -> 3.3.1
      {:swarm, "~> 3.0"}, # https://hexdocs.pm/swarm/readme.html -> 3.4.0
      {:excoveralls, "~> 0.14"}, # https://hexdocs.pm/excoveralls/ExCoveralls.html -> 0.15.0
      {:phoenix_live_view, "~> 0.15"}, # https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html -> 0.18.3
      {:floki, "~> 0.30.1", only: :test}, # https://hexdocs.pm/floki/readme.html -> 0.34.0
      {:phoenix_live_dashboard, "~> 0.4"}, # https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.PageBuilder.html -> 0.7.2
      {:hackney, "~> 1.17.4"}, # https://hexdocs.pm/hackney/ -> 1.18.1
      {:cachex, "~> 3.3"}, # 3.4.0; Última actualización20210602; https://hex.pm/packages/cachex
      {:number, "~> 1.0.1"}, # 1.0.3; Última actualización 20201001; https://hex.pm/packages/number
      {:oban, "2.7.2"}, # 2.13.5; No updated; dependencies(ecto_sql, jason,postgrex , telemetry); https://hex.pm/packages/oban
      {:prom_ex, "~> 1.0.1"}, # 1.7.1; No updated; dependencies(); https://hexdocs.pm/prom_ex/PromEx.html
      {:scrivener_ecto, "~> 2.0"} # 2.7; UPDATED; dependency(scrivener y ecto); https://hex.pm/packages/scrivener_ecto
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
