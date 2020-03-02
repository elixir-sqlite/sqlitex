defmodule Sqlitex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :sqlitex,
      version: "1.7.1",
      elixir: "~> 1.4",
      deps: deps(),
      package: package(),
      source_url: "https://github.com/elixir-sqlite/sqlitex",
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.circle": :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      description: """
      A thin Elixir wrapper around esqlite
      """,
      dialyzer: [plt_add_deps: :transitive],
      docs: [main: "readme", # The main page in the docs
             extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  def application do
    [extra_applications: [:logger]]
  end

  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:esqlite, "~> 0.4"},
      {:decimal, "~> 1.7"},
      {:credo, "~> 0.10", only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.20", only: :docs, runtime: false},
      {:excheck, "~> 0.6", only: :test},
      {:triq, "~> 1.3", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/elixir-sqlite/sqlitex",
        "docs" => "http://hexdocs.pm/sqlitex"
      }
    ]
  end
end
