# Development

## Dependencies

- [Elixir 1.10+]

## Getting Started

Install project dependencies:

```sh
$ make install
```

To build the source:

```sh
$ make build
```

To see other make tasks:

```sh
$ make
```

## Running Tests and Quality Checks

To run unit tests:

```sh
$ make test
```

To run Elixir code format:

```sh
$ make format
```

To run credo:

```sh
$ make credo
```

To run dialyzer:

```sh
$ make dialyzer
```

To run everything:

```sh
$ make full-test
```

## Generating the docs

This project uses [ex_docs] to build its documentation:

```sh
$ mix docs
```

## Release

After merge a new feature/bug you can bump and publish it with:

```sh
$ make release
$ make publish
```

[Elixir 1.10+]: https://elixir-lang.org/install.html
[ex_docs]: https://hex.pm/packages/ex_doc
