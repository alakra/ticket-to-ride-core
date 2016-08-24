defmodule TicketToRide.Games.Index do
  @default_timeout 30_000

  def start_link do
    Agent.start_link(fn -> Map.new end, name: __MODULE__)
  end

  def get(id) do
    Agent.get(__MODULE__, &(Map.fetch(&1, id)), @default_timeout)
  end

  def put(id, pid) do
    Agent.get_and_update(__MODULE__, &({id, Map.put(&1, id, pid)}), @default_timeout)
  end

  def remove(id) do
    Agent.get_and_update(__MODULE__, &({id, Map.drop(&1, [id])}), @default_timeout)
  end

  def all do
    Agent.get(__MODULE__, &(&1), @default_timeout)
  end
end
