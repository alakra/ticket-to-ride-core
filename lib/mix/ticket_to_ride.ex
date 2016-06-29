defmodule Mix.TicketToRide do
  def options(:server, args) do
    ["--server" | args]
    |> general_options
  end

  def options(:client, args) do
    args |> general_options
  end

  def run_args do
    if iex_running?, do: [], else: ["--no-halt"]
  end

  # Private

  defp general_options(args) do
    args |> TicketToRide.CLI.parse_options
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
