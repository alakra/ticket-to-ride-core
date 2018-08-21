# Ticket To Ride (Core Implementation, No Network)

This is an implementation of Ticket to Ride (the Amercian version) in
Elixir. It not only has the mechanics of the board game, but also
manages player registration, session management and delegation of
player actions to the correct game states.

NOTE: This is a work in progress and not all goals have been met
yet. When this message disappears, then it'll be done. :)

### Why?

There are so many implementations of Ticket To Ride. Why build another
one?

Board games have a wide scope of features when they get implemented as
software because they exercise most of the logic and state
management that we programmers know we need to experience to really
get a feel for the breadth of a computer language.

Good board games have the following features:

* They have to mantain state.
* They have physical domain which makes them easier to reason about.
* They have rules.
* They have (usually) more than 1 player.
* They have secrets.
* They have limited effects due to randomness.

In addition to the above, I chose Ticket to Ride because it also
requires calculations on a graph.

My real interest was to build a proof-of-concept game server that
could manage the state of thousands of turn-based games on a single
server without going to great lengths to configure the server.

I wanted to do this without thinking about networking and
transport-layer security, so I focused on state management and scaling
the game to over 10k concurrent games.

### What I Have Learned From This Project

My original implementation tried to do too much (core gameplay, state,
networking and a terminal client), so I scaled it back to focus on the
core gameplay and managing state.

I learned that:

* Domain-Driven APIs are so much easier to debug when you constrain
  yourself to contexts (see [Phoenix Contexts](https://hexdocs.pm/phoenix/contexts.html#content))

* `typespecs` will tell you how simple or insane your APIs are in
  Elixir. Write them for every public function.

* Not all domains are physical. New ones will appear as you see
  consistent patterns on data manipulation.

* Defining documentation on modules that are in the first-level of the
  domain is really important. It's even more important to actually
  render them using `mix docs` and expand the `Functions` drop-down
  for every top-level domain module. It reveals a lot about what you
  can do with a module. Verb-Noun structure (e.g. `get_card/2`) is
  simple and clear.

* Good tests make a foundation not for correctness, but for
  identifying what effects your code changes will produce.

* Not to return `nil` from functions. I won't do it. I will always try
  to return something unambiguous.

## Features

* Only five top-level domains: `Board`, `Cards`, `Games`, `Mechanics` and `Players`
* User registration (username and password)
* Separation of player contexts vs complete state
* Ownership tied to first player to join a new game. Will transfer to next player if first player leaves, etc.
* Session management (provided concept for future implementations over a network to validate actions before they hitting the core the API)
* Can scale just over 10k concurrent games on a small virtual machine (1 cpu, 1 GB ram)
* Single-time sliced timer for all turns (turns are limited to 30 seconds)
* Randomly chooses which player goes first

## Non-Features

* No graphical UI
* No persistent database
* No network support
* No transport-level security

These things belongs elsewhere.

## Installation and Setup

### Requirements

* You must have `elixir` >= `1.6` with `mix` installed
* You must have `git` installed
* You must be running 64-bit linux or macos (>= high sierra)

### Installation

```shell
git clone https://github.com/alakra/ticket-to-ride-core.git
cd ticket-to-ride-core
mix deps.get
mix compile
```

Then start it up:

```shell
iex -S mix
```

### Runbook

You can run the following in the `IEx` console. If you need more
context, see the [official rules](https://www.daysofwonder.com/tickettoride/en/usa) for the game.

Make sure you alias first:

```elixir
alias TtrCore.{
  Board,
  Games,
  Players
}

alias TtrCore.Board.Route
alias TtrCore.Games.Context
```

#### Game Setup

```elixir
{:ok, user_id_a} = Players.register("playerA", "p@ssw0rd!")
{:ok, user_id_b} = Players.register("playerB", "p@ssw0rd!")

# NOTE: `login/2` is also supported with sessions, but only makes sense in the context of a network.

{:ok, game_id, _pid} = Games.create(user_id_a)

:ok = Games.join(game_id, user_id_b)
:ok = Games.setup(game_id, user_id_a)

{:ok, %{tickets_buffer: tickets_a}} = Games.get_context(game_id, user_id_a)
:ok = Games.perform(game_id, user_id_a, {:select_tickets, tickets_a})

{:ok, %{tickets_buffer: tickets_b}} = Games.get_context(game_id, user_id_b)
Games.perform(game_id, user_id_b, {:select_tickets, tickets_b})

:ok = Games.begin(game_id, user_id_a)
```

#### Game Turns

##### Find out who goes first

```elixir
{:ok, context_a} = Games.get_context(id, user_id_a)
{:ok, context_b} = Games.get_context(id, user_id_b)

starting_context = Enum.find([context_a, context_b], fn c ->
    c.current_player == c.id
end)
```

Let's assume `user_id_a` gets to go first. Possible actions are
detailed in the following sections.

Also, make sure you get the latest context after each operation:

```elixir
{:ok, context_a} = Games.get_context(id, user_id_a)
```

##### Claim a route

```elixir
routes = Board.get_routes() |> Map.values()
routes = (routes -- context_a.routes) -- context_b.routes

# Take a look at your routes, then make sure selections

train = :coal
cost = 5

route_to_claim = %Route{
  to: Atlanta,
  from: Miami,
  distance: 5,
  train: :coal
}

:ok = Games.perform(game_id, user_id_a, {:claim_route, route_to_claim, train, cost})
```

##### Select trains from the display

```elixir

# Find out what trains are on display

%Context{displayed_trains: displayed} = context_a
[first|_] = displayed

# Select the first train

:ok = Games.perform(game_id, user_id_a, {:select_trains, [first]})
```

##### Draw trains from the deck

```elixir
%Context{train_deck: number_in_deck} = context_a

# Draw a train if there are trains in the deck (can draw up to 2)

if number_in_deck > 0 do
  :ok = Games.perform(game_id, user_id_a, {:draw_trains, 1})
end
```

##### Draw tickets from the deck

```elixir
:ok = Games.perform(game_id, user_id_a, :draw_tickets)
```

##### Select tickets that you have drawn

```elixir
%Context{tickets_buffer: buffer} = context_a
:ok = Games.perform(game_id, user_id_a, {:select_tickets, buffer})
```

#### Ending the Game

The game will automatically end when the context struct reports that
the key `:stage` has a value of `:finished`. The keys `winner_id` will
contain the `user_id` of the player who won the game.

## License

This software is licensed under the [MIT License](LICENSE).
