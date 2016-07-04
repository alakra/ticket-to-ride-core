defmodule TicketToRide.Player.DB do
  alias TicketToRide.User

  # API

  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def get(username) do
    Agent.get(__MODULE__, &Map.get(&1, username))
  end

  def register(username, pass) do
    existing_user = get(username)

    case existing_user do
      nil ->
        Agent.update(__MODULE__, &Map.put(&1, username, %User{username: username, pass: pass}))
        :ok
      _ ->
        {:error, "User already registered."}
    end
  end

  def validate(username, pass) do
    get(username)
    |> has_valid_record
    |> has_valid_pass(pass)
  end

  # Private

  defp has_valid_record(record) do
    if record do
      record
    else
      {:error, "User does not exist."}
    end
  end

  defp has_valid_pass({:error, error}, _), do: {:error, error}
  defp has_valid_pass(record, pass) do
    if record.pass == pass do
      record
    else
      {:error, "Password does not match."}
    end
  end
end
