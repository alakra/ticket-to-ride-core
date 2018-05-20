# TicketToRide

## Summary

This is an implementation of Ticket to Ride (the Amercian version) in
Elixir. It contains a multiplayer game server and a command-line based
client. There is no single player available at this time so every
client connected must be orchestrated by a human.

## Features

## Installation and Setup

Two environments are currently supported: `local`, `otp release` and `docker`.

### Local

#### Requirements

* You must have `elixir` >= `1.6` with `mix` installed
* You must have `git` installed

#### Installation

Clone the repo:

```shell
git clone https://github.com/alakra/ticket-to-ride-core.git
```

Change to the cloned directory and install dependencies:

```shell
cd ticket-to-ride-core
mix deps.get
```

Compile the application:

```shell
mix compile
```

You should now be ready to [play a game](#playing-a-game). If it doesn't work,
please [submit an issue](https://github.com/alakra/ticket-to-ride-core/issues).

### OTP Release

### Docker

## Playing a Game

In order to play game, you must first start a server then connect
clients to it to start or join a game.

### Running a Server

Running a server is different depending on the environment used.

#### Locally

You can start a server locally by running a mix task:

```shell
mix run ttr.server
```

This will start the server with default options:

| Description                | Short | Long     | Default Value |
|----------------------------+-------+----------+---------------|
| IP of server               | -i    | --ip     |     127.0.0.1 |
| Port of server             | -p    | --port   |          7777 |
| Max Connections            | -l    | --limit  |          1000 |
| Flag for server (no value) | -s    | --server |               |

You should then see the server start:

```text
[2018-05-19T22:14:34.032Z][info] Starting server on tcp://127.0.0.1:7777 (max connections: 1000)
```

#### OTP Release

#### Docker

### Starting a Game as a Client

### Joining a Game as a Client

## Why?

### Primary Goals

I wrote this implementation of TTR so that I could experiment with
`ranch`, `msgpack` and terminal-based interactions within Elixir. I
wanted to see how well DSLs could be written with Elixir's macro
system when defining static characteristics of a turn-based game. In
TTR's case, I was able to write macros that helped me define the graph
of train routes and vathe lues of the playing cards in a very readable
way.

See [TicketToRide.Routes](lib/ticket_to_ride/routes.ex) and [TicketToRide.Tickets](lib/ticket_to_ride/tickets.ex) as
examples.

### Secondary Goals

I wanted to see how far I could push a cheap VM in the cloud to
maximize the number of connections on a single server before the
quality of service degraded.

## Development Details

### Client / Server Architecture

### OTP Architecture

### Networking Protocol Details

## License

This software is licensed under the [MIT License](LICENSE).
