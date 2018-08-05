%{configs: [
  %{name: "default",
    files: %{
      included: ["lib/", "test/", "integration/"],
      excluded: [~r"/_build/", ~r"/deps/"]
    },
    requires: [],
    check_for_updates: false,

    # You can customize the parameters of any check by adding a second element
    # to the tuple.
    #
    # To disable a check put `false` as second element:
    #
    #     {Credo.Check.Design.DuplicatedCode, false}
    #
    checks: [
      {Credo.Check.Consistency.ExceptionNames},
      {Credo.Check.Consistency.LineEndings},
      {Credo.Check.Consistency.MultiAliasImportRequireUse},
      {Credo.Check.Consistency.ParameterPatternMatching},
      {Credo.Check.Consistency.SpaceAroundOperators},
      {Credo.Check.Consistency.SpaceInParentheses},
      {Credo.Check.Consistency.TabsOrSpaces},

      {Credo.Check.Design.AliasUsage, false},
      {Credo.Check.Design.DuplicatedCode, excluded_macros: []},

      # Disabled for now as those are checked by Code Climate
      {Credo.Check.Design.TagTODO, false},
      {Credo.Check.Design.TagFIXME, false},

      {Credo.Check.Readability.FunctionNames},
      {Credo.Check.Readability.LargeNumbers},
      {Credo.Check.Readability.MaxLineLength, false},
      {Credo.Check.Readability.ModuleAttributeNames},
      {Credo.Check.Readability.ModuleDoc},
      {Credo.Check.Readability.ModuleNames},
      {Credo.Check.Readability.ParenthesesInCondition},
      {Credo.Check.Readability.PredicateFunctionNames},
      {Credo.Check.Readability.PreferImplicitTry, false},
      {Credo.Check.Readability.RedundantBlankLines},
      {Credo.Check.Readability.Semicolons},
      {Credo.Check.Readability.SinglePipe, false},
        # ^^ Ecto does this quite a bit and we want to follow their
        # code format closely, so silence this warning.

      {Credo.Check.Readability.SpaceAfterCommas},
      {Credo.Check.Readability.Specs, false},
      {Credo.Check.Readability.StringSigils, false},
        # ^^ Ecto does this quite a bit and we want to follow their
        # code format closely, so silence this warning.

      {Credo.Check.Readability.TrailingBlankLine},
      {Credo.Check.Readability.TrailingWhiteSpace},
      {Credo.Check.Readability.VariableNames},
      {Credo.Check.Readability.RedundantBlankLines},

      {Credo.Check.Refactor.ABCSize, false},
      {Credo.Check.Refactor.CondStatements},
      {Credo.Check.Refactor.CyclomaticComplexity},
      {Credo.Check.Refactor.DoubleBooleanNegation, false},
      {Credo.Check.Refactor.FunctionArity, max_arity: 8},
      {Credo.Check.Refactor.MatchInCondition},
      {Credo.Check.Refactor.PipeChainStart, false},
      {Credo.Check.Refactor.NegatedConditionsInUnless},
      {Credo.Check.Refactor.NegatedConditionsWithElse},
      {Credo.Check.Refactor.Nesting},
      {Credo.Check.Refactor.UnlessWithElse},
      {Credo.Check.Refactor.VariableRebinding, false},

      {Credo.Check.Warning.BoolOperationOnSameValues},
      {Credo.Check.Warning.IExPry},
      {Credo.Check.Warning.IoInspect, false},
      {Credo.Check.Warning.OperationOnSameValues, false},
        # Disabled because of p.x == p.x in Ecto queries
      {Credo.Check.Warning.OperationWithConstantResult},
      {Credo.Check.Warning.UnusedEnumOperation},
      {Credo.Check.Warning.UnusedFileOperation},
      {Credo.Check.Warning.UnusedKeywordOperation},
      {Credo.Check.Warning.UnusedListOperation},
      {Credo.Check.Warning.UnusedPathOperation},
      {Credo.Check.Warning.UnusedRegexOperation},
      {Credo.Check.Warning.UnusedStringOperation},
      {Credo.Check.Warning.UnusedTupleOperation},
    ]
  }
]}
