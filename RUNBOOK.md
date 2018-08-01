# Core Usage (after application startup)

## Player Setup

```
:ok = TtrCore.Player.DB.register("playerA", "p@ssw0rd!")
{:ok, sessionA} = TtrCore.Player.Session.new("playerA", "p@ssw0rd!")

:ok = TtrCore.Player.DB.register("playerB", "p@ssw0rd!")
{:ok, sessionB} = TtrCore.Player.Session.new("playerB", "p@ssw0rd!")
```

## Game Setup

```
{:ok, id, pid} = TtrCore.Games.create(sessionA.user_id)
{:ok, ids} = TtrCore.Games.list()

:ok = TtrCore.Games.join(id, sessionB.user_id)
:ok = TtrCore.Games.begin(id, sessionA.user_id)

{:ok, destination_cards} = TtrCore.Games.perform(id, sessionA.user_id, :select_initial_destination_cards)
:ok = TtrCore.Games.perform(id, sessionA.user_id, {:select_initial_destination_cards, Enum.take_random(destination_cards, 2)})

{:ok, destination_cards} = TtrCore.Games.perform(id, sessionB.user_id, :select_initial_destination_cards)
:ok = TtrCore.Games.perform(id, sessionB.user_id, {:select_initial_destination_cards, Enum.take_random(destination_cards, 2)})

:ok = TtrCore.Games.is_ready(id, sessionA.user_id)
:ok = TtrCore.Games.is_ready(id, sessionB.user_id)

# Game turns start as soon everyone is ready. First player is chosen at random.
```

## Game Play

```
# Look at state to see if the current turn belongs to user in `state.current_player`
{:ok, state} = TtrCore.Games.get_info(id, sessionA.user_id)

# Possible actions

## Draw face up train cards
{:ok, train_cards} = TtrCore.Games.perform(id, sessionA.user_id, :draw_faceup_train_cards)
:ok = TtrCore.Games.perform(id, sessionA.user_id {:draw_faceup_train_cards, Enum.take_random(train_cards, 1)})

## Draw deck train cards
{:ok, train_cards} = TtrCore.Games.perform(id, sessionA.user_id, :draw_deck_train_cards)
:ok = TtrCore.Games.perform(id, sessionA.user_id {:draw_deck_train_cards, Enum.take_random(train_cards, 1)})

## Claim Route
:ok = TtrCore.Games.perform(id, sessionA.user_id, {:claim_route, :atlanta_to_charleston})

## Draw destination
{:ok, destinations} = TtrCore.Games.perform(id, sessionA.user_id, :draw_destination_cards)
:ok = TtrCore.Games.perform(id, sessionA.user_id {:draw_destination_cards, Enum.take_random(destinations, 1)})
```

## Game Finishing

Game keeps going until 0, 1, or 2 trains are left for any player or if there is only one player or left less.

```
:ok = TtrCore.Games.leave(id, sessionB.user_id)
:ok = TtrCore.Games.leave(id, sessionA.user_id)
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
