# MetaLogger

[![Hex.pm](https://img.shields.io/hexpm/v/meta_logger.svg)](https://hex.pm/packages/meta_logger)
[![Docs](https://img.shields.io/badge/hex-docs-542581.svg)](https://hexdocs.pm/meta_logger)
[![Build Status](https://github.com/FindHotel/meta_logger/workflows/build/badge.svg?branch=master)](https://github.com/FindHotel/meta_logger/actions?query=branch%3Amaster)
[![License](https://img.shields.io/hexpm/l/meta_logger.svg)](https://github.com/FindHotel/meta_logger/blob/master/LICENSE)

MetaLogger is a wrapper for Elixir `Logger` that keeps and returns the logger metadata from the
caller processes.

## Installation

The package can be installed by adding `meta_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:meta_logger, "~> 1.6.1"}
  ]
end
```

MetaLogger requires Elixir 1.10 or greater. For previous Elixir versions use MetaLogger `0.1.0`.

## Usage

Just replace `Logger` with `MetaLogger`, there is no need to require it before using:

```elixir
MetaLogger.[debug|error|info|log|warning](...)
```

For processes that can continue running after the parent process ends, the `MetaLogger` will not
be able to get the caller processes metadata if the parent process is finished. In this case, the
`MetaLogger.metadata/0` function can be used to store the metadata before the process starts:

```elixir
metadata = MetaLogger.metadata()

Task.async(fn ->
  Logger.metadata(metadata)
end)
```

## Tesla Middleware

A middleware to log requests and responses using [Tesla](https://hexdocs.pm/tesla).

## Installation

If you want to use the MetaLogger Tesla middleware, optional dependencies are required. Add the
following to your `mix.exs`:

```elixir
def deps do
  [
    {:tesla, "~> 1.4"},
    {:miss, "~> 0.1"}
  ]
end
```

### Usage example

```elixir
defmodule MyClient do
  use Tesla

  plug Tesla.Middleware.MetaLogger,
    filter_body: {~r/email=.*&/, "email=[FILTERED]&"}
    filter_headers: ["authorization"],
    filter_query_params: [:api_key],
    log_level: :debug,
    log_tag: MyApp,
    max_entry_length: 22_000
end
```

### Options

See the [`Tesla.Middleware.MetaLogger`](https://hexdocs.pm/meta_logger/Tesla.Middleware.MetaLogger.html)
documentation for the options definition.

## MetaLogger.Formatter protocol

It is possible to define an implementation for a custom struct, so MetaLogger will know how to
format log messages. It also includes the possibility to filter some data using regexp patterns.

It could be useful, when there is a defined struct with sensitive information, for example after
an HTTP request. If you own the struct, you can derive the implementation specifying a formatter
function and patterns which will be filtered.

The struct for which implementation will be used must have the `payload` field, which is used as
input for the defined format function.

`MetaLogger.log/3` accepts the structs which derives `MetaLogger.Formatter` implementation.

### Usage

```elixir
defmodule ClientFormatterImpl do
  @derive {
    MetaLogger.Formatter,
    formatter_fn: &__MODULE__.format/1,
    filter_patterns: [
      {~s/"name":".*"/, ~s/"name":"[FILTERED]"/},
      "very_secret_word"
    ]
  }

  def build(payload) do
    struct!(__MODULE__, payload: payload)
  end

  def format(%{foo: foo}) do
    "Very useful but filtered information: #{inspect(foo)}"
  end
end

# Inside the build function a logic can be defined to extract an useful payload
# which needs to belogged, e.g. a request and response information.
http_request
|> ClientFormatterImpl.build()
|> then(fn log_struct -> MetaLogger.log(:debug, log_struct) end)
```

### Options

- `:formatter_fn` (required) - The function which is used to format a given payload. The function
  must return a string or a list of strings.
- `:filter_patterns` (optional) - Regex patterns which will be used to replace sensitive
  information in a payload. It is a list of strings or tuples (can be mixed). If tuples are given,
  the first element is used as a regex pattern to match, and the second is as a replacement which
  will be used to replace it. E.g. `{~s/"name": ".+"/, ~s/"name": "[FILTERED]"/}`.

## Full documentation

The full documentation is available at [https://hexdocs.pm/meta_logger](https://hexdocs.pm/meta_logger).

## Contributing

See the [contributing guide](https://github.com/FindHotel/meta_logger/blob/master/CONTRIBUTING.md).

## License

MetaLogger is released under the Apache 2.0 License. See the
[LICENSE](https://github.com/FindHotel/meta_logger/blob/master/LICENSE) file.

Copyright © 2019-2021 FindHotel

## Author

[FindHotel](https://github.com/FindHotel)

<a href="https://careers.findhotel.net" title="FindHotel Careers" target="_blank"><img height="150" src="https://raw.githubusercontent.com/FindHotel/meta_logger/master/assets/fh-loves-elixir-holo.png" alt="FindHotel loves Elxir!"></a>
