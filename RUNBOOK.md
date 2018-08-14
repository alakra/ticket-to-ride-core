# Core Usage (after application startup)

## Player Setup

```
{:ok, player_id_a} = TtrCore.Players.register("playerA", "p@ssw0rd!")
{:ok, session_a} = TtrCore.Players.login("playerA", "p@ssw0rd!")

{:ok, player_id_b} = TtrCore.Players.register("playerB", "p@ssw0rd!")
{:ok, session_b} = TtrCore.Players.login("playerB", "p@ssw0rd!")
```

## Game Setup

```
{:ok, id, pid} = TtrCore.Games.create(session_a.user_id)
{:ok, ids} = TtrCore.Games.list()

:ok = TtrCore.Games.join(id, session_b.user_id)
:ok = TtrCore.Games.begin(id, session_a.user_id)

{:ok, destination_cards} = TtrCore.Games.perform(id, session_a.user_id, :select_initial_destination_cards)
:ok = TtrCore.Games.perform(id, session_a.user_id, {:select_initial_destination_cards, Enum.take_random(destination_cards, 2)})

{:ok, destination_cards} = TtrCore.Games.perform(id, session_b.user_id, :select_initial_destination_cards)
:ok = TtrCore.Games.perform(id, session_b.user_id, {:select_initial_destination_cards, Enum.take_random(destination_cards, 2)})

:ok = TtrCore.Games.is_ready(id, session_a.user_id)
:ok = TtrCore.Games.is_ready(id, session_b.user_id)

# Game turns start as soon everyone is ready. First player is chosen at random.
```

## Game Play

```

# Look at contextual state based on the user id (don't reveal secrets of other players)

{:ok, context} = TtrCore.Games.get_context(id, session_a.user_id)

# Look at complete state of game (for testing)

{:ok, state} = TtrCore.Games.get_state(id)

# Possible actions

## Draw face up train cards
{:ok, train_cards} = TtrCore.Games.perform(id, session_a.user_id, :draw_faceup_train_cards)
:ok = TtrCore.Games.perform(id, session_a.user_id {:draw_faceup_train_cards, Enum.take_random(train_cards, 1)})

## Draw deck train cards
{:ok, train_cards} = TtrCore.Games.perform(id, session_a.user_id, :draw_deck_train_cards)
:ok = TtrCore.Games.perform(id, session_a.user_id {:draw_deck_train_cards, Enum.take_random(train_cards, 1)})

## Claim Route
:ok = TtrCore.Games.perform(id, session_a.user_id, {:claim_route, :atlanta_to_charleston})

## Draw destination
{:ok, destinations} = TtrCore.Games.perform(id, session_a.user_id, :draw_destination_cards)
:ok = TtrCore.Games.perform(id, session_a.user_id {:draw_destination_cards, Enum.take_random(destinations, 1)})
```

## Game Finishing

Game keeps going until 0, 1, or 2 trains are left for any player or if there is only one player or left less.

```
:ok = TtrCore.Games.leave(id, session_b.user_id)
:ok = TtrCore.Games.leave(id, session_a.user_id)

:ok = TtrCore.Player.logout(session_b.user_id)
:ok = TtrCore.Player.logout(session_a.user_id)
```

# Quick and Dirty

```
{:ok, :registered} = TicketToRide.Client.register("user_a", "pass")
{:ok, token_a} = TicketToRide.Client.login("user_a", "pass")
{:ok, game_id} = TicketToRide.Client.create(token_a, [])
{:ok, :registered} = TicketToRide.Client.register("user_b", "pass")
{:ok, token_b} = TicketToRide.Client.login("user_b", "pass")
{:ok, {:joined, _}} = TicketToRide.Client.join(token_b, game_id)
{:ok, :began} = TicketToRide.Client.begin(token_a, game_id)
```

# Full Runbook

## Create a user and game with that user

```
{:ok, :registered} = TicketToRide.Client.register("user_a", "pass")
{:ok, token_a} = TicketToRide.Client.login("user_a", "pass")
{:ok, game_id} = TicketToRide.Client.create(token_a, [])
```

## Check a list

```
{:ok, [first|remainder]} = TicketToRide.Client.list
```

## Create another user

```
{:ok, :registered} = TicketToRide.Client.register("user_b", "pass")
{:ok, token_b} = TicketToRide.Client.login("user_b", "pass")
```

## Join a specific game

```
{:ok, {:joined, _}} = TicketToRide.Client.join(token_b, game_id)
```

## Leave a specific game

```
{:ok, :left} = TicketToRide.Client.leave(token_b, game_id)
{:ok, :left} = TicketToRide.Client.leave(token_a, game_id)
```

## Join first available game

```
{:ok, {:joined, actual_id}} = TicketToToRide.Client.join(token_b, :any)
```

## Start game

```
{:ok, :began} = TicketToRide.Client.begin(token_a, game_id)
```
