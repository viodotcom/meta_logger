import Config

config :logger, :default_formatter, metadata: [:foo, :bar, :baz]
