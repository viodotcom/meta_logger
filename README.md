# MetaLogger

[![Build Status](https://travis-ci.com/FindHotel/meta_logger.svg?branch=master)](https://travis-ci.com/FindHotel/meta_logger)

Wrapper for Elixir.Logger that keeps logger metadata from caller processes.

## Installation

MetaLogger requires Elixir 1.10 or greater. For previous versions use MetaLogger `0.1.0`.

The package is [available in Hex](https://hex.pm/packages/meta_logger), and can be installed
by adding `meta_logger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:meta_logger, "~> 1.0.0"}
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

## Release

After merge a new feature/bug you can bump and publish it with:

```sh
make release
make publish
```

## License
`meta_logger` source code is released under Apache 2 License. Check the [LICENSE](./LICENSE) file for more information.
