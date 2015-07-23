defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlitex,
     version: "0.8.0",
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     description: """
      A thin Elixir wrapper around esqlite
    """]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger]]
  end

  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:esqlite, "~> 0.2.0"},
      {:pipe, "~> 0.0.2"},
      {:decimal, "~> 1.1.0"},

      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_doc, "~> 0.7", only: :dev},
      {:inch_ex, "~> 0.2", only: :dev},
    ]
  end

  defp package do
   [contributors: ["Michael Ries", "Jason M Barnes"],
     licenses: ["MIT"],
     links: %{
      github: "https://github.com/mmmries/sqlitex",
      docs: "http://hexdocs.pm/sqlitex"}]
  end
end
