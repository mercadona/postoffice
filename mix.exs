defmodule Postoffice.MixProject do
  use Mix.Project

  def project do
    [
      app: :postoffice,
      version: "0.19.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
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
      {:phoenix, "1.6.15"},
      {:phoenix_pubsub, "2.1.1"},
      {:phoenix_ecto, "4.4.0"},
      {:ecto_sql, "3.7.2"},
      {:postgrex, "0.16.5"},
      {:phoenix_html, "3.2.0"},
      {:phoenix_live_view, "0.18.3"},
      {:phoenix_live_dashboard, "0.7.2"},
      {:phoenix_live_reload, "1.4.0", only: :dev},
      {:gettext, "0.20.0"},
      {:jason, "1.4.0"},
      {:plug_cowboy, "2.5.2"},
      {:bcrypt_elixir, "3.0.1"},
      {:google_api_pub_sub, "0.36.0"},
      {:goth, "1.3.1"},
      {:httpoison, "1.8.2"},
      {:mox, "1.0.0", only: :test},
      {:gen_stage, "0.14.3"},
      {:ink, "1.2.1"},
      {:config_tuples, "0.4.2"},
      {:libcluster, "3.3.1"},
      {:swarm, "3.4.0"},
      {:excoveralls, "0.15.1"},
      {:floki, "0.34.0", only: :test},
      {:hackney, "1.18.1"},
      {:cachex, "3.4.0"},
      {:number, "1.0.3"},
      {:oban, "2.13.5"},
      {:prom_ex, "1.7.1"},
      {:scrivener_ecto, "2.7.0"}
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
