import Config

config :logger, :default_formatter, metadata: ~w(bar baz foo request_id)a
