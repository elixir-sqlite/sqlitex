defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlitex,
     version: "0.0.1",
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
      {:esqlite, git: "https://github.com/mmzeeman/esqlite.git", tag: "9967ced039246f75f66a3891f584b1f150e56463"}
    ]
  end

  defp package do
   [contributors: ["Michael Ries"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/mmmries/sqlitex"}]
  end
end
