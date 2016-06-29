defmodule TicketToRide.Mixfile do
  use Mix.Project

  def project do
    [app: :ticket_to_ride,
     version: "1.0.0",
     elixir: "~> 1.3",
     escript: escript,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :ranch],
     mod: {TicketToRide, []}]
  end

  defp escript do
    [main_module: TicketToRide.CLI,
     emu_args: "-noinput -elixir ansi_enabled true"]
  end

  defp deps do
    [
      {:ranch, "~> 1.2"},
      {:msgpax, "~> 0.8"},
      {:socket, "~> 0.3"},
      {:uuid, "~> 1.1"},
      {:connection, "~> 1.0"}
    ]
  end
end
