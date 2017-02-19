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

  describe "RETURNING pseudo-syntax" do
    test "returns id from a single row insert" do
      {:ok, db} = Sqlitex.open(":memory:")

      Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

      stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES (?1) "
                                            <> ";--RETURNING ON INSERT x,id")

      rows = Sqlitex.Statement.fetch_all!(stmt)
      assert rows == [[id: 1]]
    end

    test "returns id from a single row insert as a raw list" do
      {:ok, db} = Sqlitex.open(":memory:")

      Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

      stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES (?1) "
                                            <> ";--RETURNING ON INSERT x,id")

      rows = Sqlitex.Statement.fetch_all!(stmt, :raw_list)
      assert rows == [[1]]
    end

    test "returns id from a multi-row insert" do
      {:ok, db} = Sqlitex.open(":memory:")

      Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

      stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES ('x'),('y'),('z') "
                                            <> ";--RETURNING ON INSERT x,id")

      rows = Sqlitex.Statement.fetch_all!(stmt)
      assert rows == [[id: 1], [id: 2], [id: 3]]
    end

    test "returns id from a multi-row insert as a raw list" do
      {:ok, db} = Sqlitex.open(":memory:")

      Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

      stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES ('x'),('y'),('z') "
                                            <> ";--RETURNING ON INSERT x,id")

      rows = Sqlitex.Statement.fetch_all!(stmt, :raw_list)
      assert rows == [[1], [2], [3]]
    end
  end
end
