use Mix.Config

config :dogma,
  rule_set: Dogma.RuleSet.All,

  exclude: [
    ~r(\Atest/test_database.exs),
  ],
  additional_config: [
    LineLength: [max_length: 100]
  ]
