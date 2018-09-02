defmodule TtrCore.Mechanics do
  @moduledoc """
  Game play mechanics, rules and state transformer.
  """

  @type cost :: integer
  @type count :: integer

  alias TtrCore.{
    Board,
    Cards,
    Players
  }

  alias TtrCore.Mechanics.{
    Context,
    OtherPlayer,
    Score,
    State
  }

  alias TtrCore.Players.{
    Player,
    User
  }

  # API

  @max_players 4

  @doc """
  Checks to see if the state allows going to the `setup` stage.

  Returns `:ok`, if it can.

  Returns `{:error, :not_owner}` if the user id used is not the owner
  requesting the stage change.

  Returns `{:error, :not_enough_players}` if the game does not have
  more than 1 player joined.

  Returns `{:error, :not_in_unstarted}` if the game is not in the
  `unstarted` stage.
  """
  @spec can_setup?(State.t, User.id) :: :ok |
    {:error, :not_owner | :not_enough_players | :not_in_unstarted}
  def can_setup?(%{owner_id: owner_id, players: players} = state, user_id) do
    []
    |> validate_owner(owner_id, user_id)
    |> validate_enough_players(players)
    |> validate_game_unstarted(state)
    |> handle_result()
  end

  @doc """
  Checks to see if the state allows going to the `begin` stage.

  Returns `:ok`, if it can.

  Returns `{:error, :not_owner}` if the user id used is not the owner
  requesting the stage change.

  Returns `{:error, :not_enough_players}` if the game does not have
  more than 1 player joined.

  Returns `{:error, :not_in_setup}` if the game is not in the
  `unstarted` stage.

  Returns `{:error, :tickets_not_selected}` if any of the players have
  not selected their initial tickets.
  """
  @spec can_begin?(State.t, User.id) :: :ok |
  {:error, :not_owner | :not_enough_players | :not_in_setup | :tickets_not_selected}
  def can_begin?(%{owner_id: owner_id, players: players} = state, user_id) do
    []
    |> validate_tickets_selected(state)
    |> validate_owner(owner_id, user_id)
    |> validate_enough_players(players)
    |> validate_game_in_setup(state)
    |> handle_result()
  end

  @doc """
  Checks to see if a player can join.

  Returns `:ok` if it is possible.

  Returns `{:error, :game_full}` if the game has reach the maximum
  number of players (4).

  Returns `{:error, :already_joined}` if the player has already
  joined.
  """
  @spec can_join?(State.t, User.id) :: :ok | {:error, :game_full | :already_joined}
  def can_join?(%{players: players}, user_id) do
    []
    |> validate_not_full(players)
    |> validate_no_duplicate_players(players, user_id)
    |> handle_result()
  end

  @doc """
  Checks to see if a player has already joined and returns a boolean.
  """
  @spec is_joined?(State.t, User.id) :: boolean()
  def is_joined?(%{players: players}, user_id) do
    Enum.any?(players, fn %{id: stored_id} -> stored_id == user_id end)
  end

  @doc """
  Adds a player to the state.
  """
  @spec add_player(State.t, User.id) :: State.t
  def add_player(%{players: players} = state, user_id) do
    %{state | players: Players.add_player(players, user_id)}
  end

  @doc """
  Removes a player from the state.  If the player is the owner, then
  another player is automatically assigned as the owner.
  """
  @spec remove_player(State.t, User.id) :: State.t
  def remove_player(%{players: players} = state, user_id) do
    updated_players = Players.remove_player(players, user_id)

    state
    |> Map.put(:players, updated_players)
    |> transfer_ownership_if_host_left
  end

  @doc """
  Randomly chooses starting player.
  """
  @spec choose_starting_player(State.t) :: State.t
  def choose_starting_player(%{players: players} = state) do
    %Player{id: id} = Players.select_random_player(players)
    %{state | current_player: id}
  end

  @doc """
  Transforms game state to a `setup` stage. This stage will:

  * Deal initial trains to players (4 to each player)
  * Deal tickets for selections to players (3 to each player)
  * Displays 5 trains face up for all user to select during normal
    gameplay
  """
  @spec setup_game(State.t) :: State.t
  def setup_game(state) do
    state
    |> deal_trains()
    |> deal_tickets()
    |> display_trains()
    |> Map.put(:stage, :setup)
  end

  @doc """
  Transforms game state to a `started` stage. This stage will:

  * Choose a starting player
  """
  @spec start_game(State.t) :: State.t
  def start_game(state) do
    state
    |> choose_starting_player()
    |> Map.put(:stage, :started)
    |> Map.put(:stage_meta, [])
  end

  @doc """
  Deals trains to all players during the `setup` stage or a normal turn
  (`started` stage). Called by `setup_game/1`.
  """
  @spec deal_trains(State.t) :: State.t
  def deal_trains(%{train_deck: train_deck, players: players} = state) do
    {remaining, updated} = Cards.deal_initial_trains(train_deck, players)

    state
    |> Map.put(:train_deck, remaining)
    |> Map.put(:players, updated)
  end

  @doc """
  Draws trains to a player from the a train deck. Can draw 1 or 2 cards.
  """
  @spec draw_trains(State.t, User.id, count()) :: {:ok, State.t}
  def draw_trains(%{train_deck: deck, players: players} = state, user_id, count) do
    player = Players.find_by_id(players, user_id)
    {remainder, updated_player} = Cards.draw_trains(deck, player, count)
    updated_players = Players.replace_player(players, updated_player)

    new_state = state
    |> Map.put(:train_deck, remainder)
    |> Map.put(:players, updated_players)

    {:ok, new_state}
  end

  @doc """
  Deals tickets to all players during the `setup` stage. Called by
  `setup_game/1`.
  """
  @spec deal_tickets(State.t) :: State.t
  def deal_tickets(%{ticket_deck: deck, players: players} = state) do
    {remaining, updated} = Cards.deal_tickets(deck, players)

    state
    |> Map.put(:ticket_deck, remaining)
    |> Map.put(:players, updated)
  end

  @doc """
  Draw tickets from deck to a player for selections.
  """
  @spec draw_tickets(State.t, User.id) :: State.t
  def draw_tickets(%{ticket_deck: deck, players: players} = state, user_id) do
    player = Players.find_by_id(players, user_id)
    {new_deck, updated_player} = Cards.draw_tickets(deck, player)
    updated_players = Players.replace_player(players, updated_player)

    state
    |> Map.put(:ticket_deck, new_deck)
    |> Map.put(:players, updated_players)
  end

  @doc """
  Select tickets that were drawn into buffer for a player.

  Returns `{:ok, state}` if selections were successful.

  Returns `{:error, :invalid_tickets}` if the tickets selected were
  not available to be chosen.
  """
  @spec select_tickets(State.t, User.id, [TicketCard.t]) ::
  {:ok, State.t} | {:error, :invalid_tickets}
  def select_tickets(%{ticket_deck: ticket_deck, players: players} = state, user_id, tickets) do
    player = Players.find_by_id(players, user_id)

    if Players.has_tickets?(player, tickets) do
      {updated_player, removed} = player
      |> Players.add_tickets(tickets)
      |> Players.remove_tickets_from_buffer(tickets)

      updated_players = Players.replace_player(players, updated_player)
      updated_tickets = Cards.return_tickets(ticket_deck, removed)

      new_state = state
      |> Map.put(:ticket_deck, updated_tickets)
      |> Map.put(:players, updated_players)
      |> update_meta(user_id)

      {:ok, new_state}
    else
      {:error, :invalid_tickets}
    end
  end

  @doc """
  Select trains from the display deck and replenish train display.

  Returns `{:ok, state}` if selections were successful.

  Returns `{:error, :invalid_trains}` if the trains selected were
  not available to be chosen.
  """
  @spec select_trains(State.t, User.id, [TrainCard.t]) ::
  {:ok, State.t} | {:error, :invalid_trains}
  def select_trains(%{players: players, train_deck: train_deck, displayed_trains: displayed} = state, user_id, trains) do
    player = Players.find_by_id(players, user_id)
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

  @doc """
  Claims a route for a player and pays out the cost in trains.

  Returns `{:ok, state}` if succesful.

  Returns `{:error, :unavailable}` if the route is not eligible to be
  claimed.
  """
  @spec claim_route(State.t, User.id, Route.t, TrainCard.t, cost()) ::
  {:ok, State.t} | {:error, :unavailable}
  def claim_route(%{players: players, discard_deck: discard} = state, user_id, route, train, cost) do
    %{trains: trains, pieces: pieces} = player = Players.find_by_id(players, user_id)

    claimed   = Players.get_claimed_routes(players)
    claimable = Board.get_claimable_routes(claimed, player, Enum.count(players))

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

  @doc """
  Generates a player's context from the game state.  This includes the
  view a player has of other players (not including their secrets or
  the details of decks).
  """
  @spec generate_context(State.t, User.id) :: Context.t
  def generate_context(%{players: players} = state, user_id) do
    player = Players.find_by_id(players, user_id)

    other_players = players
    |> Enum.reject(fn %{id: id} -> id == user_id end)
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

  @doc """
  End a player's turn.

  Returns `{:ok, state}` if successful.

  Returns `{:error, :not_turn}` if it is not the user id of the
  current player.
  """
  @spec end_turn(State.t, User.id()) :: {:ok, State.t} | {:error, :not_turn}
  def end_turn(%{current_player: current_id} = state, user_id) do
    if user_id == current_id do
      {:ok, force_end_turn(state)}
    else
      {:error, :not_turn}
    end
  end

  @doc """
  Force the end of a turn regardless of player identification. Used by
  the `Ticker` timer.
  """
  @spec force_end_turn(State.t) :: State.t
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
      # Get baseline scores for every player
      scores = Enum.map(players, &(calculate_score(&1)))

      # Get longest route length from player pool
      {_, _, _, longest} = Enum.max_by(scores, fn {_, _, _, length} -> length end)

      # Separate all players that scored the longest length route from everyone else
      {high_scorers, remainder} = Enum.split_with(scores, fn {_, _, _, length} ->
        length == longest
      end)

      # Apply bonus points to high scorers and calculate final scores
      achievers = Enum.map(high_scorers, fn {id, route_score, ticket_score, _} ->
        {id, ticket_score + route_score + 10}
      end)

      others = Enum.map(remainder, fn {id, route_score, ticket_score, _} ->
        {id, ticket_score + route_score}
      end)

      finals = achievers ++ others

      # Calculate winner
      {winner_id, score} = Enum.max_by(finals, fn {_, score} -> score end)

      %{state |
        winner_id: winner_id,
        winner_score: score,
        scores: finals,
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

  defp calculate_score(player), do: Score.calculate(player)

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

  defp update_meta(%{stage: :setup} = state, user_id) do
    if Enum.member?(state.stage_meta, user_id) do
      state
    else
      %{state | stage_meta: [user_id | state.stage_meta]}
    end
  end
  defp update_meta(%{stage: _} = state, _), do: state

  defp validate_owner(errors, owner_id, user_id) do
    if owner_id == user_id do
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

  defp validate_no_duplicate_players(errors, players, user_id) do
    if Enum.any?(players, fn %{id: stored_id} -> stored_id == user_id end) do
      [{:error, :already_joined} | errors]
    else
      errors
    end
  end

  defp handle_result(results) do
    case results do
      [error|_] -> error
      _ -> :ok
    end
  end
end
