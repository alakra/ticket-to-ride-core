defmodule TtrCore.Games.Ticker do
  use GenServer
  require Logger

  alias TtrCore.Games.{
    Game,
    Turns
  }

  @type game_id() :: binary

  # API

  @max_ticks 60

  @doc """
  Starts the `TtrCore.Games.Ticker` process.
  """
  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  @doc """
  Specifies `TtrCore.Games.Ticker` to run as a worker.
  """
  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_) do
    %{id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker}
  end

  @doc """
  """
  @spec get_current() :: non_neg_integer()
  def get_current do
    GenServer.call(__MODULE__, :current)
  end

  @doc """
  """
  @spec get_new_start_tick() :: non_neg_integer()
  def get_new_start_tick do
    GenServer.call(__MODULE__, :new_start_tick)
  end

  # Callbacks

  def init(_) do
    Process.send_after(self(), :tick, 1000)
    {:ok, 0}
  end

  def handle_info(:tick, count) do
    Process.send_after(self(), :tick, 1000)

    Registry.dispatch(Turns, :turns, fn entries ->
      Enum.each(entries,
        fn {pid, ^count} -> Game.force_next_turn(pid)
            _ -> :ok
        end)
    end)

    {:noreply, get_next_count(count)}
  end

  def handle_call(:current, _from, count) do
    {:reply, count, count}
  end

  def handle_call(:new_start_tick, _from,  count) do
    {:reply, get_next_start_count(count), count}
  end

  # Private

  defp get_next_count(count) do
    if count >= (@max_ticks - 1) do
      0
    else
      count + 1
    end
  end

  defp get_next_start_count(count) do
    new_count = count + 10

    if new_count > (@max_ticks - 1) do
      new_count - @max_ticks
    else
      new_count
    end
  end
end
