defmodule StatementTest do
  use ExUnit.Case, async: true
  doctest Sqlitex.Statement

  test "fetch_all! works" do
    {:ok, db} = Sqlitex.open(":memory:")

    result = db
              |> Sqlitex.Statement.prepare!("PRAGMA user_version;")
              |> Sqlitex.Statement.fetch_all!

    assert result == [[user_version: 0]]
  end
end
