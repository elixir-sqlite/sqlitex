defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlitex,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:esqlite, git: "https://github.com/mmzeeman/esqlite.git", tag: "9967ced039246f75f66a3891f584b1f150e56463"}
    ]
  end
end
