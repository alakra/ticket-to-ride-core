defmodule Mix.TicketToRide do
  def options(:server, args) do
    ["--server" | args]
    |> general_options
  end

  def options(:client, args) do
    args |> general_options
  end

  # Private

  defp general_options(args) do
    args |> TicketToRide.CLI.parse_options
  end
end
