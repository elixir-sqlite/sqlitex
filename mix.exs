defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sqlitex,
      version: "1.4.1",
      elixir: "~> 1.2",
      deps: deps(),
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
         "coveralls": :test,
         "coveralls.detail": :test,
         "coveralls.post": :test,
         "coveralls.html": :test],
      description: """
        A thin Elixir wrapper around esqlite
      """,
      dialyzer: [plt_add_deps: :transitive],
    ]
  end

  # Configuration for the OTP application
  def application do
    [applications: [:logger, :esqlite]]
  end

  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:esqlite, "~> 0.2.4"},
      {:decimal, "~> 1.1"},

      {:credo, "~> 0.4", only: :dev},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:earmark, "~> 1.2", only: :dev},
      {:excoveralls, "~> 0.6", only: :test},
      {:ex_doc, "~> 0.18", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev},

      {:excheck, "~> 0.5", only: :test},
      {:triq, "~> 1.2", only: :test},
    ]
  end

  defp package do
   [maintainers: ["Michael Ries", "Jason M Barnes", "Graeme Coupar", "Eric Scouten"],
     licenses: ["MIT"],
     links: %{
      github: "https://github.com/mmmries/sqlitex",
      docs: "http://hexdocs.pm/sqlitex"}]
  end
end
