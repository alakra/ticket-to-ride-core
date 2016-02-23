defmodule TicketToRide.Mixfile do
  use Mix.Project

  def project do
    [app: :ticket_to_ride,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger],
     mod: {TicketToRide, []}]
  end

  defp deps do
    []
  end
end
