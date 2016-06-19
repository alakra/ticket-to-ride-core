defmodule TicketToRide.Player.DB do
  # TODO: Persist this data in Mnesia

  alias TicketToRide.User

  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def find_by(:token, token) do
    result = Agent.get(__MODULE__, fn map ->
      Enum.find(map, fn {_, v} -> v.token == token end)
    end)

    case result do
      nil -> {:not_found}
      _   -> {:ok, result}
    end
  end

  def register(username, pass) do
    existing_user = Agent.get(__MODULE__, &Map.get(&1, username))

    case existing_user do
      nil ->
        Agent.update(__MODULE__, &Map.put(&1, username, %User{pass: pass, token: nil}))
        :ok
      _ ->
        {:error, "User already registered."}
    end
  end

  def login(username, pass) do
    Agent.get(__MODULE__, &Map.get(&1, username))
    |> has_valid_record
    |> has_valid_pass(pass)
    |> generate_token
    |> update_record(username)
  end

  # Private

  defp has_valid_record(record) do
    if record do
      record
    else
      {:error, "User does not exist."}
    end
  end

  # TODO: Use a secure password checking mechanism
  defp has_valid_pass({:error, error}, _), do: {:error, error}
  defp has_valid_pass(record, pass) do
    if record.pass == pass do
      record
    else
      {:error, "Password does not match."}
    end
  end

  defp generate_token({:error, error}), do: {:error, error}
  defp generate_token(record), do: %User{record | token: UUID.uuid1(:hex)}

  defp update_record({:error, error}, _), do: {:error, error}
  defp update_record(record, username) do
    Agent.update(__MODULE__, &Map.put(&1, username, record))
    {:ok, record.token}
  end
end
