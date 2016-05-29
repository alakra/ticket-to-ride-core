defmodule TicketToRide.CLI do
  alias TicketToRide.Version

  # API

  def main(args) do
    TicketToRide.start(:normal, parse_options(args))
    :erlang.hibernate(Kernel, :exit, [:killed])
  end

  # Private

  @aliases [
    h: :help,
    v: :version,
    p: :port,
    i: :ip,
    s: :server,
    l: :limit
  ]

  @switches [
    help: :boolean,
    version: :boolean,
    port: :integer,
    ip: :string,
    server: :boolean,
    limit: :integer
  ]

  @default_ip "127.0.0.1"
  @default_port 7777
  @default_game_limit 1000

  def default_options do
    [
      limit: @default_game_limit,
      ip: @default_ip,
      port: @default_port
    ]
  end

  def parse_options(args) do
    opts = [switches: @switches, aliases: @aliases]
    OptionParser.parse(args, opts) |> interpret_options
  end

  defp interpret_options({[], _, _}) do
    IO.puts """
    usage: ticket_to_ride [-hv] [-p PORT] [-i ADDRESS] [-s] [-l LIMIT]
    """

    Kernel.exit(:normal)
  end

  defp interpret_options({[version: true], _, _}) do
    IO.puts Version.current
    Kernel.exit(:normal)
  end

  defp interpret_options({[help: true], _, _}) do
    IO.puts """
    description: Ticket to Ride Game Client/Server

    options:
    -h, --help        Show this help message.
    -v, --version     Show version.

    -p, --port        Port to connect to for client or server. (Default: #{@default_port})
    -i, --ip          IP to bind server to or server to connect to as a client. (Default: #{@default_ip})

    -s, --server      Run as a server. (without this option, always run as client)
    -l, --limit       Limit games that can be played concurrently (Default: #{@default_game_limit})
    """

    Kernel.exit(:normal)
  end

  defp interpret_options({options, _, _}) do
    Keyword.merge(default_options, options)
  end
end
