defmodule MetaLogger.MixProject do
  use Mix.Project

  @version "0.0.0"

  def project do
    [
      app: :meta_logger,
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: "Keep logger metadata from caller processes",
      docs: [
        main: "MetaLogger",
        source_ref: @version,
        source_url: "https://github.com/FindHotel/meta_logger",
        extras: ["README.md", "CHANGELOG.md"]
      ]
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

  defp package do
    %{
      name: "meta_logger",
      licenses: ["Apache 2"],
      organization: "findhotel",
      maintainers: [
        "Antonio Lorusso",
        "Felipe Vieira",
        "Fernando Hamasaki de Amorim"
      ],
      links: %{"GitHub" => "https://github.com/FindHotel/meta_logger"},
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"]
    }
  end
end
