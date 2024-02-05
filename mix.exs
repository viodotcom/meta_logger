defmodule MetaLogger.MixProject do
  use Mix.Project

  @version "1.6.1"
  @source_url "https://github.com/FindHotel/meta_logger"

  def project do
    [
      app: :meta_logger,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      description: description(),
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "MetaLogger",
      package: package(),
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Middleware dependencies
      {:miss, "~> 0.1", optional: true},
      {:tesla, "~> 1.4", optional: true}
    ]
  end

  defp description do
    """
    A wrapper for Elixir Logger that keeps and returns the logger metadata from the caller
    processes.
    """
  end

  defp dialyzer do
    [
      plt_add_apps: [:miss, :tesla],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      canonical: "http://hexdocs.pm/meta_logger",
      extras: ~w(README.md CHANGELOG.md),
      formatters: ~w(html),
      main: "readme",
      source_ref: @version,
      source_url: @source_url
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  defp package do
    %{
      files: ~w(lib mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url},
      maintainers: ~w(OTA Tribe)
    }
  end
end
