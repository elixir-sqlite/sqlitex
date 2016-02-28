defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlitex,
     version: "0.8.3",
     elixir: "~> 1.2",
     deps: deps,
     package: package,
     description: """
      A thin Elixir wrapper around esqlite
    """]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :esqlite]]
  end

  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:esqlite, "~> 0.2.0"},
      {:decimal, "~> 1.1.0"},

      {:dialyze, "~> 0.2.0", only: :dev},
      {:earmark, "~> 0.2.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev},
    ]
  end

  defp package do
   [maintainers: ["Michael Ries", "Jason M Barnes", "Graeme Coupar"],
     licenses: ["MIT"],
     links: %{
      github: "https://github.com/mmmries/sqlitex",
      docs: "http://hexdocs.pm/sqlitex"}]
  end
end
