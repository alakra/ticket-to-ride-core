defmodule TtrCore.Games.State do
  @moduledoc false

  defstruct [
    id: nil,
    owner_id: nil,
    winner_id: :none,
    winner_score: 0,
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

  @type count :: integer
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
    Cards,
    Players
  }

  alias TtrCore.Players.Player

  alias TtrCore.Games.Context.OtherPlayer
  alias TtrCore.Games.{
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
  def add_player(%{players: players} = state, player_id) do
    %{state | players: Players.add_player(players, player_id)}
  end

  @spec remove_player(t, player_id()) :: t
  def remove_player(%{players: players} = state, player_id) do
    updated_players = Players.remove_player(players, player_id)

    state
    |> Map.put(:players, updated_players)
    |> transfer_ownership_if_host_left
  end

  @spec choose_starting_player(t) :: t
  def choose_starting_player(%{players: players} = state) do
    %Player{id: id} = Players.select_random_player(players)
    %{state | current_player: id}
  end

  @spec setup_game(t) :: t
  def setup_game(state) do
    state
    |> deal_trains()
    |> deal_tickets()
    |> display_trains()
    |> Map.put(:stage, :setup)
  end

  @spec start_game(t) :: t
  def start_game(state) do
    state
    |> choose_starting_player()
    |> Map.put(:stage, :started)
    |> Map.put(:stage_meta, [])
  end

  @spec deal_trains(t) :: t
  def deal_trains(%{train_deck: train_deck, players: players} = state) do
    {remaining, updated} = Cards.deal_initial_trains(train_deck, players)

    state
    |> Map.put(:train_deck, remaining)
    |> Map.put(:players, updated)
  end

  @spec draw_trains(t, player_id(), count) :: {:ok, t}
  def draw_trains(%{train_deck: deck, players: players} = state, player_id, count) do
    player = Players.find_by_id(players, player_id)
    {remainder, updated_player} = Cards.draw_trains(deck, player, count)
    updated_players = Players.replace_player(players, updated_player)

    new_state = state
    |> Map.put(:train_deck, remainder)
    |> Map.put(:players, updated_players)

    {:ok, new_state}
  end

  @spec deal_tickets(t) :: t
  def deal_tickets(%{ticket_deck: deck, players: players} = state) do
    {remaining, updated} = Cards.deal_tickets(deck, players)

    state
    |> Map.put(:ticket_deck, remaining)
    |> Map.put(:players, updated)
  end

  @spec draw_tickets(t, player_id()) :: t
  def draw_tickets(%{ticket_deck: deck, players: players} = state, player_id) do
    player = Players.find_by_id(players, player_id)
    {new_deck, updated_player} = Cards.draw_tickets(deck, player)
    updated_players = Players.replace_player(players, updated_player)

    state
    |> Map.put(:ticket_deck, new_deck)
    |> Map.put(:players, updated_players)
  end

  @spec select_tickets(t, player_id(), [TicketCard.t]) :: {:ok, t} | {:error, :invalid_tickets}
  def select_tickets(%{ticket_deck: ticket_deck, players: players} = state, player_id, tickets) do
    player = Players.find_by_id(players, player_id)

    if Players.has_tickets?(player, tickets) do
      {updated_player, removed} = player
      |> Players.add_tickets(tickets)
      |> Players.remove_tickets_from_buffer(tickets)

      updated_players = Players.replace_player(players, updated_player)
      updated_tickets = Cards.return_tickets(ticket_deck, removed)

      new_state = state
      |> Map.put(:ticket_deck, updated_tickets)
      |> Map.put(:players, updated_players)
      |> update_meta(player_id)

      {:ok, new_state}
    else
      {:error, :invalid_tickets}
    end
  end

  @spec select_trains(t, player_id(), [TrainCard.t]) :: {:ok, t} | {:error, :invalid_trains}
  def select_trains(%{players: players, train_deck: train_deck, displayed_trains: displayed} = state, player_id, trains) do
    player = Players.find_by_id(players, player_id)
    selected = Enum.take(trains, 2) # Only grab up to 2 trains, ignore the rest

    if Cards.has_cards?(displayed, selected) do
      updated_player  = Players.add_trains_on_turn(player, selected)
      updated_players = Players.replace_player(players, updated_player)

      {new_display, new_deck} = displayed
      |> Cards.remove_from_display(selected)
      |> Cards.replenish_display(train_deck)

      new_state = state
      |> Map.put(:players, updated_players)
      |> Map.put(:displayed_trains, new_display)
      |> Map.put(:train_deck, new_deck)

      {:ok, new_state}
    else
      {:error, :invalid_trains}
    end
  end

  @spec claim_route(t, player_id(), Route.t, TrainCard.t, integer()) :: {:ok, t} | {:error, :unavailable}
  def claim_route(%{players: players, discard_deck: discard} = state, player_id, route, train, cost) do
    %{trains: trains, pieces: pieces} = player = Players.find_by_id(players, player_id)

    claimable = Board.get_claimable_routes(players)

    has_stake  = Enum.member?(claimable, route)
    has_trains = Enum.count(trains) >= cost
    has_pieces = pieces >= cost

    if has_stake and has_trains and has_pieces do
      {updated_player, removed} = player
      |> Players.add_route(route, cost)
      |> Players.remove_trains(train, cost)

      updated_players = Players.replace_player(players, updated_player)
      new_discard = Cards.add_trains_to_discard(discard, removed)

      new_state = state
      |> Map.put(:discard_deck, new_discard)
      |> Map.put(:players, updated_players)

      {:ok, new_state}
    else
      {:error, :unavailable}
    end
  end

  @spec generate_context(t, player_id()) :: Context.t
  def generate_context(%{players: players} = state, player_id) do
    player = Players.find_by_id(players, player_id)

    other_players = players
    |> Enum.reject(fn %{id: id} -> id == player_id end)
    |> Enum.map(fn player ->
      %OtherPlayer{
        name: player.name,
        tickets: Enum.count(player.tickets),
        trains: Enum.count(player.trains),
        pieces: player.pieces,
        routes: player.routes
      }
    end)

    %Context{
      id: player.id,
      stage: state.stage,
      game_id: state.id,
      name: player.name,
      pieces: player.pieces,
      tickets: player.tickets,
      tickets_buffer: player.tickets_buffer,
      trains: player.trains,
      trains_selected: player.trains_selected,
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
  def end_turn(%{current_player: current_id} = state, player_id) do
    if player_id == current_id do
      {:ok, force_end_turn(state)}
    else
      {:error, :not_turn}
    end
  end

  @spec force_end_turn(t) :: t
  def force_end_turn(%{players: players, current_player: current_id} = state) do
    count = Enum.count(players)
    index = Enum.find_index(players, fn %{id: id} -> id == current_id end)

    # Find out the next player's id and set it
    next = if index == (count - 1), do: 0, else: count - 1
    %{id: id} = Enum.at(players, next)

    new_state = state
    |> reset_players_selections()
    |> Map.put(:current_player, id)
    |> move_stage()

    new_state
  end

  # Private

  defp move_stage(%{current_player: id, stage: :last_round, stage_meta: meta, players: players} = state) do
    if all_players_played_last_round?(players, meta) do
      {winner_id, score} = calculate_winner(players)

      %{state |
        winner_id: winner_id,
        winner_score: score,
        stage: :finished,
        stage_meta: []}
    else
      %{state | stage_meta: [id|meta]}
    end
  end
  defp move_stage(%{stage: :started, players: players} = state) do
    if Players.any_out_of_stock?(players) do
      %{state | stage: :last_round, stage_meta: []}
    else
      state
    end
  end
  defp move_stage(%{stage: _} = state), do: state

  defp calculate_winner(players) do
    players
    |> Enum.map(&({&1.id, calculate_score(&1)}))
    |> Enum.max_by(fn {_, score} -> score end)
  end

  defp calculate_score(%{routes: routes}) do
    routes
    |> Enum.map(fn {_, _, distance, _} -> calculate_route_score(distance) end)
    |> Enum.sum()
  end

  defp calculate_route_score(6), do: 15
  defp calculate_route_score(5), do: 10
  defp calculate_route_score(4), do: 7
  defp calculate_route_score(3), do: 4
  defp calculate_route_score(2), do: 2
  defp calculate_route_score(1), do: 1

  defp all_players_played_last_round?(players, meta) do
    ids = players |> Enum.map(&(&1.id)) |> Enum.sort()
    meta_ids = Enum.sort(meta)

    ids == meta_ids
  end

  defp reset_players_selections(%{players: players} = state) do
    %{state | players: Enum.map(players, &(Players.reset_selections(&1)))}
  end

  defp display_trains(%{displayed_trains: displayed, train_deck: deck} = state) do
    {display, new_deck} = Cards.replenish_display(displayed, deck)
    %{state| train_deck: new_deck, displayed_trains: display}
  end

  defp transfer_ownership_if_host_left(%{players: players, owner_id: owner_id} = state) do
    result = Enum.any?(players, &(&1.id == owner_id))

    new_owner_id = case List.first(players) do
                     nil -> :none
                     %{id: id} -> id
                   end

    if result do
      %{state | owner_id: new_owner_id}
    else
      state
    end
  end

  defp update_meta(%{stage: :setup} = state, player_id) do
    if Enum.member?(state.stage_meta, player_id) do
      state
    else
      %{state | stage_meta: [player_id | state.stage_meta]}
    end
  end
  defp update_meta(%{stage: _} = state, _), do: state

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
