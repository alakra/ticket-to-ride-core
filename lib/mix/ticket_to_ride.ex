defmodule Mix.TicketToRide do
  def options(:server, args) do
    ["--server" | args]
    |> general_options
  end

  def options(:client, args) do
    general_options(args)
  end

  def run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  # Private

  defp general_options(args) do
    TicketToRide.CLI.parse_options(args)
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
