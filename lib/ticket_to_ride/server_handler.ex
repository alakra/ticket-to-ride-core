defmodule TicketToRide.ServerHandler do
  @behaviour :ranch_protocol
  @timeout 2 * 60 * 1000 # 2 minutes

  require Logger

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
      {:error, :closed} ->
        Logger.info "Connection Closed:"
        Process.exit(self, :normal)
      {:error, :timeout} ->
        Logger.info "Connection Timed Out:"
        Process.exit(self, :normal)
    end
  end

  defp handle_data(socket, transport, data) do
    case Msgpax.unpack(data) do
      {:ok, payload} ->
        transport.send(socket, payload |> interpret |> respond_with)
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

  defp perform(["list", _]) do
    [:list, Server.games, "\n"]
  end

  defp perform(["register", user, pass, _]) do
    [:register, Server.register(user, pass), "\n"]
  end

  defp perform(["login", user, pass, _]) do
    [:login, Server.login(user, pass), "\n"]
  end

  defp perform(["statistics", "\n"]) do
  end

  # Context User Token

  defp perform(["logout", token]) do
  end

  defp perform(["status", token]) do
  end

  defp perform(["join", token, game_id]) do
  end

  defp perform(["create", token, options]) do
  end

  defp perform(["leave", token, options]) do
  end

  # Game Actions

  defp perform(["action", token, game_id, payload]) do
  end

  # No op

  defp perform(msg), do: [:unknown_message, msg, "\n"]
end
