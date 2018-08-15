# Runbook

Recipes for doing fundamental things in the debug console.

## Aliasing

```
alias TtrCore.{
  Games,
  Players
}

```

## Player Setup

```
{:ok, player_id_a} = Players.register("playerA", "p@ssw0rd!")
{:ok, session_a} = Players.login("playerA", "p@ssw0rd!")

{:ok, player_id_b} = Players.register("playerB", "p@ssw0rd!")
{:ok, session_b} = Players.login("playerB", "p@ssw0rd!")
```

## Game Setup

```
{:ok, id, pid} = Games.create(session_a.user_id)
{:ok, ids} = Games.list()

:ok = Games.join(id, session_b.user_id)

:ok = Games.setup(id, session_a.user_id)

{:ok, %{tickets_buffer: tickets_a}} = Games.get_context(id, session_a.user_id)
:ok = Games.perform(id, session_a.user_id, {:select_ticket_cards, tickets_a})

{:ok, %{tickets_buffer: tickets_b}} = Games.get_context(id, session_b.user_id)
Games.perform(id, session_b.user_id, {:select_ticket_cards, tickets_b})

:ok = Games.begin(id, session_a.user_id)

# Game turns start as soon game begins. First player is chosen at random.
```

## Game Play

```
{:ok, context} = Games.get_context(id, session_a.user_id)
{:ok, state} = Games.get_state(id)

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
