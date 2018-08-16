defmodule TtrCore.Games.State do
  @moduledoc false

  defstruct [
    id: nil,
    owner_id: nil,
    players: [],
    routes: [],
    ticket_deck: [],
    displayed_trains: [],
    train_deck: [],
    discard_deck: [],
    current_player: nil,
    stage: :unstarted,
    stage_meta: [],
    longest_path_owner: nil
  ]

  @type stage :: :unstarted | :setup | :started | :last_round | :finished
  @type meta :: list()
  @type player_id :: binary()

  @type t :: %__MODULE__{
    current_player: player_id(),
    stage: stage(),
    stage_meta: meta()
  }

  alias TtrCore.{
    Board,
    Players
  }

  alias TtrCore.Players.Player

  alias TtrCore.Games.Context.OtherPlayer
  alias TtrCore.Games.{
    Action,
    Context
  }

  # API

  @max_players 4

  @spec can_setup?(t, player_id()) :: :ok |
    {:error, :not_owner | :not_enough_players | :not_in_unstarted}
  def can_setup?(%{owner_id: owner_id, players: players} = state, player_id) do
    []
    |> validate_owner(owner_id, player_id)
    |> validate_enough_players(players)
    |> validate_game_unstarted(state)
    |> handle_result()
  end

  @spec can_begin?(t, player_id()) :: :ok |
  {:error, :not_owner | :not_enough_players | :not_in_setup | :tickets_not_selected}
  def can_begin?(%{owner_id: owner_id, players: players} = state, player_id) do
    []
    |> validate_tickets_selected(state)
    |> validate_owner(owner_id, player_id)
    |> validate_enough_players(players)
    |> validate_game_in_setup(state)
    |> handle_result()
  end

  @spec can_join?(t, player_id()) :: :ok | {:error, :game_full | :already_joined}
  def can_join?(%{players: players}, player_id) do
    []
    |> validate_not_full(players)
    |> validate_no_duplicate_players(players, player_id)
    |> handle_result()
  end

  @spec is_joined?(t, player_id()) :: :ok | {:error, :not_joined}
  def is_joined?(%{players: players}, player_id) do
    []
    |> validate_player_joined(players, player_id)
    |> handle_result()
  end

  @spec add_player(t, player_id()) :: t
  def add_player(state, player_id) do
    %{state | players: [%Player{id: player_id} | state.players]}
  end

  @spec remove_player(t, player_id()) :: t
  def remove_player(state, player_id) do
    index = Enum.find_index(state.players, &(&1.id == player_id))
    new_players = List.delete_at(state.players, index)

    %{state | players: new_players}
    |> transfer_ownership_if_host_left
  end

  @spec choose_starting_player(t) :: t
  def choose_starting_player(%{players: players} = state) do
    %Player{id: chosen_id} = Enum.random(players)
    %{state | current_player: chosen_id}
  end

  @spec setup_game(t) :: t
  def setup_game(state) do
    %{state | stage: :setup}
  end

  @spec start_game(t) :: t
  def start_game(state) do
    %{state | stage: :started, stage_meta: []}
  end

  @spec deal_trains(t, fun()) :: t
  def deal_trains(%{train_deck: train_deck, players: players} = state, fun) do
    {remaining_deck, updated_players} =
      Enum.reduce(players, {train_deck, []}, fn player, {deck, acc} ->
        {:ok, remainder, player} = fun.(deck, player)
        {remainder, acc ++ [player]}
      end)

    %{state | train_deck: remaining_deck, players: updated_players}
  end

  @spec deal_tickets(t, fun()) :: t
  def deal_tickets(%{ticket_deck: ticket_deck, players: players} = state, fun) do
    {remaining_deck, updated_players} =
      Enum.reduce(players, {ticket_deck, []}, fn player, {deck, acc} ->
        {:ok, remainder, player} = fun.(deck, player)
        {remainder, acc ++ [player]}
      end)

    %{state | ticket_deck: remaining_deck, players: updated_players}
  end

  @spec select_tickets(t, player_id(), [TicketCard.t]) :: {:ok, t} | {:error, :invalid_tickets}
  def select_tickets(%{players: players} = state, player_id, tickets) do
    player = Enum.find(players, fn %{id: id} -> id == player_id end)

    if player_has_tickets?(player, tickets) do
      {updated_player, removed} = player
      |> Players.add_tickets(tickets)
      |> Players.remove_tickets_from_buffer(tickets)

      new_state = state
      |> return_tickets(removed)
      |> replace_player(updated_player)
      |> update_meta(player_id)

      {:ok, new_state}
    else
      {:error, :invalid_tickets}
    end
  end

  @spec claim_route(t, player_id(), Route.t, TrainCard.t, integer()) :: {:ok, t} | {:error, :unavailable}
  def claim_route(%{players: players} = state, player_id, route, train, cost) do
    routes = Board.get_routes() |> Map.values()

    %{trains: trains} = player = Enum.find(players, fn %{id: id} ->
      id == player_id
    end)

    claimable = Enum.reduce(players, routes, fn %{routes: taken}, acc ->
      acc -- taken
    end)

    has_stake = Enum.member?(claimable, route)
    has_trains = Enum.count(trains, &(&1 == train)) >= cost

    if has_stake and has_trains do
      {updated_player, removed} = player
      |> Players.add_route(route)
      |> Players.remove_trains(train, cost)

      new_state = state
      |> discard_trains(removed)
      |> replace_player(updated_player)

      {:ok, new_state}
    else
      {:error, :unavailable}
    end
  end

  @spec display_trains(t, fun()) :: t
  def display_trains(%{train_deck: deck} = state, fun) do
    {display, new_deck} = fun.(deck)
    %{state| train_deck: new_deck, displayed_trains: display}
  end

  @spec generate_context(t, player_id()) :: Context.t
  def generate_context(%{players: players} = state, player_id) do
    player = Enum.find(players, fn %{id: id} -> id == player_id end)

    other_players = players
    |> Enum.reject(fn %{id: id} -> id == player_id end)
    |> Enum.map(fn player ->
      %OtherPlayer{
        name: player.name,
        tickets: Enum.count(player.tickets),
        trains: Enum.count(player.trains),
        pieces: player.pieces,
        routes: player.routes,
        track_score: player.track_score
      }
    end)

    %Context{
      id: player.id,
      game_id: state.id,
      name: player.name,
      tickets: player.tickets,
      tickets_buffer: player.tickets_buffer,
      trains: player.trains,
      routes: player.routes,
      train_deck: Enum.count(state.train_deck),
      ticket_deck: Enum.count(state.ticket_deck),
      displayed_trains: state.displayed_trains,
      current_player: state.current_player,
      other_players: other_players,
      longest_path_owner: state.longest_path_owner
    }
  end

  @spec end_turn(t, player_id()) :: {:ok, t} | {:error, :not_turn}
  def end_turn(%{players: players, current_player: current_id} = state, player_id) do
    if player_id == current_id do
      count = Enum.count(players)
      index = Enum.find_index(players, fn %{id: id} -> id == player_id end)

      next = if index == (count - 1), do: 0, else: count - 1
      %{id: id} = Enum.at(players, next)

      {:ok, %{state | current_player: id}}
    else
      {:error, :not_turn}
    end
  end

  # Private

  defp transfer_ownership_if_host_left(state) do
    result = Enum.any?(state.players, fn player -> player.id == state.owner_id end)

    if result do
      %{state | owner_id: List.first(state.players).id}
    else
      state
    end
  end

  defp player_has_tickets?(%{tickets_buffer: buffer}, tickets) do
    Enum.all?(tickets, fn ticket -> Enum.member?(buffer, ticket) end)
  end

  defp replace_player(%{players: players} = state, %{id: id} = player) do
    index = Enum.find_index(players, fn player -> player.id == id end)
    updated_players = List.replace_at(players, index, player)
    %{state | players: updated_players}
  end

  defp return_tickets(state, tickets) do
    %{state | ticket_deck: state.ticket_deck ++ tickets}
  end

  defp discard_trains(%{discard_deck: existing} = state, removed) do
    %{state | discard_deck: existing ++ removed}
  end

  defp update_meta(%{stage: :setup} = state, player_id) do
    if Enum.member?(state.stage_meta, player_id) do
      state
    else
      %{state | stage_meta: [player_id | state.stage_meta]}
    end
  end

  defp validate_owner(errors, owner_id, player_id) do
    if owner_id == player_id do
      errors
    else
      [{:error, :not_owner} | errors]
    end
  end

  defp validate_enough_players(errors, players) do
    if Enum.count(players) > 1 do
      errors
    else
      [{:error, :not_enough_players} | errors]
    end
  end

  defp validate_game_unstarted(errors, %{stage: stage}) do
    if stage == :unstarted do
      errors
    else
      [{:error, :not_in_unstarted} | errors]
    end
  end

  defp validate_game_in_setup(errors, %{stage: stage}) do
    if stage == :setup do
      errors
    else
      [{:error, :not_in_setup} | errors]
    end
  end

  defp validate_not_full(errors, players) do
    if Enum.count(players) >= @max_players do
      [{:error, :game_full} | errors]
    else
      errors
    end
  end

  defp validate_tickets_selected(errors, %{players: players, stage_meta: meta}) do
    ids = Enum.map(players, fn player -> player.id end)

    if Enum.all?(ids, fn id -> Enum.member?(meta, id) end) do
      errors
    else
      [{:error, :tickets_not_selected} | errors]
    end
  end

  defp validate_no_duplicate_players(errors, players, player_id) do
    if Enum.any?(players, fn %{id: stored_id} -> stored_id == player_id end) do
      [{:error, :already_joined} | errors]
    else
      errors
    end
  end

  defp validate_player_joined(errors, players, player_id) do
    if Enum.any?(players, fn %{id: stored_id} -> stored_id == player_id end) do
      errors
    else
      [{:error, :not_joined} | errors]
    end
  end

  defp handle_result(results) do
    case results do
      [error|_] -> error
      _ -> :ok
    end
  end
end
