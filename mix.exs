defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlitex,
     version: "0.0.7",
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
      {:esqlite, "~> 0.0.4"}
    ]
  end

  defp package do
   [contributors: ["Michael Ries"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/mmmries/sqlitex"}]
  end
end
