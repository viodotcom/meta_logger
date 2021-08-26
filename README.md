# MetaLogger

![meta_logger](https://github.com/FindHotel/meta_logger/workflows/meta_logger/badge.svg?branch=master)

Wrapper for Elixir.Logger that keeps and returns logger metadata from caller processes.

## Installation

MetaLogger requires Elixir 1.10 or greater. For previous versions use MetaLogger `0.1.0`.

The package is [available in Hex](https://hex.pm/packages/meta_logger), and can be installed
by adding `meta_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:meta_logger, "~> 1.4.1"}
  ]
end
```

Documentation is generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). The docs can be found at
[https://hexdocs.pm/meta_logger](https://hexdocs.pm/meta_logger).

## Usage

Just replace `Logger` with `MetaLogger`, there's no need to require it before using:

```elixir
MetaLogger.[debug|error|info|log|warn](...)
```

```elixir
MetaLogger.metadata()
```

## Tesla Middleware

Logs requests and responses.

## Installation

Optionally MetaLogger requires another two dependencies, if you want to use the Tesla
middleware, add those dependencies to your `mix.exs`:

```elixir
def deps do
  [
    {:tesla, "~> 1.4"},
    {:miss, "~> 0.1"},
  ]
end
```

### Example usage

```elixir
defmodule MyClient do
  use Tesla

  plug #{inspect(__MODULE__)},
    filter_body: {~r/email=.*&/, "email=[FILTERED]&"}
    filter_headers: ["authorization"],
    filter_query_params: [:api_key],
    log_level: :debug,
    log_tag: MyApp,
    max_entry_length: 22_000
end
```

### Options

- `:filter_headers` - The headers that should not be logged,
  the values will be replaced with `[FILTERED]`, defaults to: `[]`.
- `:filter_query_params` - The query params that should not be logged,
  the values will be replaced with `[FILTERED]`, defaults to: `[]`.
- `:filter_body` - The request and response body patterns that should not be logged,
  each filter can be just a pattern, wich will be replaced by `"[FILTERED]"`, or it
  can be a tuple with the pattern and the replacement. Because the body filtering is
  applied to strings it is necessary that this middleware is the last one on the stack, so
  it receives the request body already encoded and the response body not yet decoded. If the
  body is not a string, the filtering will be skipped.
- `:log_level` - The log level to be used, defaults to: `:info`. Responses with
  HTTP status 400 and above will be logged with `:error`, and redirect with `:warn`.
- `:log_tag` - The log tag to be prefixed in the logs, default to: `#{inspect(__MODULE__)}`.
- `max_entry_length` - The maximum length of a log entry before it is splitted into new
  ones. Defaults to `:infinity`.

## MetaLogger.Formatter protocol

It is possible to define an implementation for a custom struct, so MetaLogger will know how to format log messages. It also includes the possibility to filter some data using regexp patterns.

It could be useful, when there is defined a struct with sensitive information, for example after an HTTP request.

If you own the struct, you can derive the implementation specifying a formatter function and patterns which will be filtered.

The struct for which implementation will be used must have `payload` field which is used as input for defined format function.

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

# Using it:
http_request
# Inside the build function a logic can be defined to extract an useful payload which
# needs to be logged, e.g. a request and response information.
|> ClientFormatterImpl.build()
|> then(fn log_struct -> MetaLogger.log(:debug, log_struct) end)
```

### Options

- `:formatter_fn` (required) - The function which is used to format a given payload. The function must return a string or a list of strings.
- `:filter_patterns` (optional) - Regex patterns which will be used to replace sensitive information in a payload. It is a list of strings or tuples (can be mixed). If tuples are given, the first element is used as a regex pattern to match, and the second is as a replacement which will be used to replace it, e.g. `{~s/"name": ".+"/, ~s/"name": "[FILTERED]"/}`.

## Release

After merge a new feature/bug you can bump and publish it with:

```sh
make release
make publish
```

## License

`meta_logger` source code is released under Apache 2 License. Check the [LICENSE](./LICENSE) file for more information.
