defmodule TtrCore.Mixfile do
  use Mix.Project

  def project do
    [app: :ttr_core,
     version: "1.0.0",
     elixir: "~> 1.6",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.post": :test,
                         "coveralls.html": :test]
    ]
  end

  def application do
    [applications: [:logger],
     mod: {TtrCore, []}]
  end

  # Private

  defp aliases do
    [test: "test --no-start --max-cases 1"]
  end

  defp deps do
    [
      # All
      {:observer_cli, "~> 1.3"},
      {:uuid, "~> 1.1"},

      # Test
      {:excoveralls, "~> 0.9", only: :test},

      # Development
      {:dialyzex, "~> 1.1", only: :dev},
      {:benchee, "~> 0.13", only: :dev},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
    ]
  end
end
