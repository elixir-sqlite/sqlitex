defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [app: :sqlitex,
     version: "1.1.1",
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

      {:credo, "~> 0.4", only: :dev},
      {:dialyze, "~> 0.2.0", only: :dev},
      {:earmark, "1.0.3", only: :dev},
        # v1.1 introduces a deprecation warning that causes a lot of console
        # noise when used with current as-of-this-writing version of exdoc (0.14.5)
      {:excoveralls, "~> 0.6", only: :test},
      {:ex_doc, "~> 0.14.5", only: :dev},
      {:inch_ex, "~> 0.5", only: :dev},

      {:excheck, "~> 0.5", only: :test},
      {:triq, github: "triqng/triq", only: :test},
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
