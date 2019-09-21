defmodule FootballSeasons.MixProject do
  use Mix.Project

  def project do
    [
      app: :football_seasons,
      version: "0.9.0",
      elixir: "~> 1.8.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: [
        main: "FootballSeasons",
        extras: ["README.md"]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {FootballSeasons.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :memento,
        :plug_cowboy,
        :nimble_csv,
        :comeonin,
        :exprotobuf
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
      # Framework
      {:phoenix, "~> 1.4.10"},
      {:phoenix_pubsub, "~> 1.1"},

      # Database
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:ecto_observable, "~> 0.4"},
      # Caching database for providing high speed searching for seasons
      {:memento, "~> 0.3.1"},

      # Tools
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:nimble_csv, "~> 0.3"},
      {:timex, "~> 3.6"},
      {:exprotobuf, "~> 1.2.17"},

      # Authorization
      {:bcrypt_elixir, "~> 2.0"},
      {:comeonin, "~> 5.0"},
      {:guardian, "~> 1.0"},

      # Code quality
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},

      # Test
      {:ex_machina, "~> 2.3", only: [:test]}
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
