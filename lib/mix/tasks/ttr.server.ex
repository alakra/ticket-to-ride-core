defmodule Mix.Tasks.Ttr.Server do
  use Mix.Task

  alias Mix.TicketToRide, as: TTR

  @shortdoc "Starts a TicketToRide Server"

  def run(args) do
    Application.put_env(:ticket_to_ride, :options, TTR.options(:server, args))
    Mix.Task.run "run", TTR.run_args
  end
end
