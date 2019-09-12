defmodule MetaLogger.MixProject do
  use Mix.Project

  @version "0.0.0"

  def project do
    [
      app: :meta_logger,
      deps: deps(),
      description: "Keep logger metadata from caller processes",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.9",
      package: package(),
      source_url: "https://github.com/FindHotel/meta_logger",
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
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end

  defp dialyzer do
    [
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
      links: %{"GitHub" => "https://github.com/FindHotel/meta_logger"},
      maintainers: [
        "Antonio Lorusso",
        "Felipe Vieira",
        "Fernando Hamasaki de Amorim"
      ],
      name: "meta_logger",
      organization: "findhotel"
    }
  end
end
