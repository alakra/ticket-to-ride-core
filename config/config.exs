use Mix.Config

config :logger, :console,
  format: "[$dateT$timeZ][$level] $metadata$message\n",
  metadata: []
