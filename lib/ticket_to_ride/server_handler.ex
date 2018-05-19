defmodule TicketToRide.ServerHandler do
  @behaviour :ranch_protocol
  @timeout 60 * 60 * 1000 # 60 minutes

  require Logger

  alias TicketToRide.Server

  # API

  def start_link(ref, socket, transport, opts) do
    {:ok, spawn_link(__MODULE__, :init, [ref, socket, transport, opts])}
  end

  def init(ref, socket, transport, _opts = []) do
    :ok = :ranch.accept_ack(ref)
    id = UUID.uuid1(:hex)
    Logger.info "Connection Opened: #{id}"
    wait_for_data(socket, transport, id)
  end

  # Private

  defp wait_for_data(socket, transport, id) do
    case transport.recv(socket, 0, @timeout) do
      {:ok, data} ->
        handle_data(socket, transport, data, id)
      {:error, :closed} ->
        Logger.info "Connection Closed: #{id}"
        Process.exit(self(), :normal)
      {:error, :timeout} ->
        Logger.warn "Connection Timed Out: #{id}"
        Process.exit(self(), :normal)
    end
  end

  defp handle_data(socket, transport, data, id) do
    case Msgpax.unpack(data) do
      {:ok, [payload|["\n"]]} ->
        transport.send(socket, payload |> perform |> respond_with)
      {:error, reason} ->
        transport.send(socket, respond_with([:error, reason]))
      _ ->
        transport.send(socket, respond_with([:error, "cannot be unpacked"]))
    end

    wait_for_data(socket, transport, id)
  end

  defp respond_with(payload) do
    Msgpax.pack!([payload|["\n"]])
  end

  # Context Free

  defp perform(["list"]) do
    case Server.games do
      {:ok, list} -> list
      {:error, msg} -> %{error: msg}
    end
  end

  defp perform(["register", user, pass]) do
    case Server.register(user, pass) do
      :ok -> :registered
      {:error, msg} -> %{error: msg}
    end
  end

  defp perform(["login", user, pass]) do
    case Server.login(user, pass) do
      {:ok, token} -> token
      {:error, msg} -> %{error: msg}
    end
  end

  # Context User Token

  defp perform(["create", token, options]) do
    case Server.create(token, options) do
      {:ok, game_id} -> game_id
      {:error, msg} -> %{error: msg}
    end
  end

  defp perform(["join", token, game_id]) do
    case Server.join(token, game_id) do
      {:ok, :joined} -> %{joined: game_id}
      {:error, msg} -> %{error: msg}
    end
  end

  defp perform(["leave", token, game_id]) do
    case Server.leave(token, game_id) do
      {:ok, :left} -> %{ok: "left"}
      {:error, msg} -> %{error: msg}
    end
  end

  defp perform(["begin", token, game_id]) do
    case Server.begin(token, game_id) do
      {:ok, :began} -> %{began: game_id}
      {:error, msg} -> %{error: msg}
    end
  end

  defp perform(["logout", token]) do
  end

  defp perform(["status", token]) do
  end

  # Game Actions

  defp perform(["action", token, game_id, payload]) do
  end

  # No op

  defp perform(msg) do
    [:unknown_message, msg]
  end
end
