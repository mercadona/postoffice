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
      {:phoenix, "~> 1.5.8"},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_ecto, "~> 4.2"},
      {:ecto_sql, "~> 3.6.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.14.1"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:gettext, "~> 0.18.2"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:bcrypt_elixir, "~> 2.3"},
      {:google_api_pub_sub, "~> 0.28.1"},
      {:goth, "~> 1.1.0"},
      {:httpoison, "~> 1.8"},
      {:mox, "~> 0.5", only: :test},
      {:gen_stage, "~> 0.14"},
      {:ink, "~> 1.0"},
      {:config_tuples, "~> 0.4"},
      {:libcluster, "~> 3.2"},
      {:swarm, "~> 3.0"},
      {:excoveralls, "~> 0.14"},
      {:phoenix_live_view, "~> 0.15"},
      {:floki, "~> 0.30.1", only: :test},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:hackney, "~> 1.17.4"},
      {:cachex, "~> 3.3"},
      {:number, "~> 1.0.1"},
      {:oban, "2.7.2"},
      {:prom_ex, "~> 1.0.1"},
      {:scrivener_ecto, "~> 2.0"}
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
