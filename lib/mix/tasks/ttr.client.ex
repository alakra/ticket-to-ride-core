defmodule Mix.Tasks.Ttr.Client do
  use Mix.Task

  alias Mix.TicketToRide, as: TTR

  @shortdoc "Starts a TicketToRide Client"

  def run(args) do
    Application.put_env(:ticket_to_ride, :options, TTR.options(:client, args))
    Mix.Task.run "run", []
  end
end
