defmodule TtrCore.Mixfile do
  use Mix.Project

  def project do
    [app: :ttr_core,
     version: "1.0.0",
     elixir: "~> 1.6",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
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

      # Development
      {:dialyzex, "~> 1.1.0", only: :dev},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
    ]
  end
end
