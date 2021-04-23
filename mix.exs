defmodule MetaLogger.MixProject do
  use Mix.Project

  @version "1.2.0"
  @source_url "https://github.com/FindHotel/meta_logger"

  def project do
    [
      app: :meta_logger,
      deps: deps(),
      description: "Keep logger metadata from caller processes",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.10",
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
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},

      # Middleware dependencies
      {:miss, "~> 0.1", optional: true},
      {:tesla, "~> 1.4", optional: true}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:miss, :tesla],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: @version
    ]
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"],
      licenses: ["Apache 2"],
      links: %{"GitHub" => @source_url},
      maintainers: [
        "Antonio Lorusso",
        "Felipe Vieira",
        "Fernando Hamasaki de Amorim",
        "Sergio Rodrigues"
      ],
      name: "meta_logger"
    }
  end
end
