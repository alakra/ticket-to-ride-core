defmodule TicketToRide.ServerHandler do
  @behaviour :ranch_protocol
  @timeout 2 * 60 * 1000 # 2 minutes

  alias TicketToRide.Server

  # API

  def start_link(ref, socket, transport, opts) do
    {:ok, spawn_link(__MODULE__, :init, [ref, socket, transport, opts])}
  end

  def init(ref, socket, transport, _opts = []) do
    :ok = :ranch.accept_ack(ref)
    wait_for_data(socket, transport)
  end

  # Private

  defp wait_for_data(socket, transport) do
    case transport.recv(socket, 0, @timeout) do
      {:ok, data} -> handle_data(socket, transport, data)
      {:error, :closed} -> Process.exit(self, :normal)
    end
  end

  defp handle_data(socket, transport, data) do
    case Msgpax.unpack(data) do
      {:ok, payload} ->
        transport.send(socket, payload |> interpret |> respond_with |> IO.inspect)
      {:error, reason} ->
        transport.send(socket, respond_with([:error, reason]))
    end

    wait_for_data(socket, transport)
  end

  defp respond_with(payload) do
    Msgpax.pack!(payload)
  end

  defp interpret(payload) do
    try do
      payload |> perform
    catch
      e -> [] # TODO: Add some error handling for bad payloads
    end
  end

  # Context Free

  defp perform(["list", "\n"]) do
    [:list, Server.games, "\n"]
  end

  defp perform(["statistics"]) do
  end

  defp perform(["register", user, pass]) do
  end

  defp perform(["login", user, pass]) do
  end

  # Context User Token

  defp perform(["status", token]) do
  end

  defp perform(["join", token, game_id]) do
  end

  defp perform(["create", token, options]) do
  end

  defp perform(["leave", token, options]) do
  end

  defp perform(["quit", token]) do
  end

  # Game Actions

  defp perform(["action", token, game_id, payload]) do
  end

  # No op

  defp perform(msg), do: [:unknown_message, msg, "\n"]
end
