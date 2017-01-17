defmodule StatementTest do
  use ExUnit.Case, async: true
  doctest Sqlitex.Statement

  test "fetch_all! works" do
    {:ok, db} = Sqlitex.open(":memory:")

    result = Sqlitex.Statement.prepare!(db, "PRAGMA user_version;")
             |> Sqlitex.Statement.fetch_all!

    assert result == [[user_version: 0]]
  end

  test "prepare retains original SQL" do
    {:ok, db} = Sqlitex.open(":memory:")
    {:ok, stmt} = Sqlitex.Statement.prepare(db, "SELECT 123;")
    assert stmt.sql == "SELECT 123;"
  end
end
