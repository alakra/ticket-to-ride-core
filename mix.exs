defmodule TtrCore.Mixfile do
  use Mix.Project

  def project do
    [app: :ttr_core,
     version: "1.0.0",
     elixir: "~> 1.9",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()
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
      # Development
      {:benchee, "~> 1.0", only: :dev},
      {:credo, "~> 1.2", only: :dev},
      {:dialyzex, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
    ]
  end
end
