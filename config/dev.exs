use Mix.Config

defmodule Sqlitex.DogmaRuleSet do
  @behaviour Dogma.RuleSet
  def rules do
    [
      {BarePipeChainStart},
      {ComparisonToBoolean},
      {DebuggerStatement},
      {ExceptionName},
      {FinalCondition},
      {FinalNewline},
      {FunctionArity, max: 4},
      {FunctionName},
      {HardTabs},
      {LineLength, max_length: 100},
      {LiteralInCondition},
      {LiteralInInterpolation},
      {MatchInCondition},
      {ModuleAttributeName},
      {ModuleDoc},
      {ModuleName},
      {NegatedIfUnless},
      {PredicateName},
      {QuotesInString},
      {Semicolon},
      {TrailingBlankLines},
      {TrailingWhitespace},
      {UnlessElse},
      {VariableName},
      {WindowsLineEndings},
    ]
  end
end


config :dogma,
  rule_set: Sqlitex.DogmaRuleSet,
  exclude: [
    ~r(\Atest/test_database.exs),
  ]
