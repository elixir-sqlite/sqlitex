defmodule Sqlitex.StatementTest do
  use ExUnit.Case, async: true
  doctest Sqlitex.Statement

  test "fetch_all! works" do
    {:ok, db} = Sqlitex.open(":memory:")

    result = db
              |> Sqlitex.Statement.prepare!("PRAGMA user_version;")
              |> Sqlitex.Statement.fetch_all!(db_timeout: 1_000)

    assert result == [[user_version: 0]]
  end

  test "fetch_all! works with db_chunk_size" do
    {:ok, db} = Sqlitex.open(":memory:")

    result = db
              |> Sqlitex.Statement.prepare!("PRAGMA user_version;")
              |> Sqlitex.Statement.fetch_all!(db_timeout: 1_000, db_chunk_size: 1_000)

    assert result == [[user_version: 0]]
  end

  test "RETURNING pseudo-syntax returns id from a single row insert" do
    {:ok, db} = Sqlitex.open(":memory:")

    Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

    stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES (?1) "
                                          <> ";--RETURNING ON INSERT x,id")

    rows = Sqlitex.Statement.fetch_all!(stmt, db_timeout: 1_000)
    assert rows == [[id: 1]]
  end

  test "RETURNING pseudo-syntax returns id from a single row insert as a raw list" do
    {:ok, db} = Sqlitex.open(":memory:")

    Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

    stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES (?1) "
                                          <> ";--RETURNING ON INSERT x,id")

    rows = Sqlitex.Statement.fetch_all!(stmt, into: :raw_list)
    assert rows == [[1]]
  end

  test "RETURNING pseudo-syntax returns id from a multi-row insert" do
    {:ok, db} = Sqlitex.open(":memory:")

    Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

    stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES ('x'),('y'),('z') "
                                          <> ";--RETURNING ON INSERT x,id")

    rows = Sqlitex.Statement.fetch_all!(stmt, db_timeout: 1_000)
    assert rows == [[id: 1], [id: 2], [id: 3]]
  end

  test "RETURNING pseudo-syntax returns id from a multi-row insert as a raw list" do
    {:ok, db} = Sqlitex.open(":memory:")

    Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")

    stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES ('x'),('y'),('z') "
                                          <> ";--RETURNING ON INSERT x,id")

    rows = Sqlitex.Statement.fetch_all!(stmt, db_timeout: 1_000, into: :raw_list)
    assert rows == [[1], [2], [3]]
  end

  test "RETURNING pseudo-syntax doesn't mask error when query fails" do
    {:ok, db} = Sqlitex.open(":memory:")

    Sqlitex.exec(db, "CREATE TABLE x(id INTEGER PRIMARY KEY AUTOINCREMENT, str)")
    Sqlitex.exec(db, "CREATE UNIQUE INDEX x_str ON x(str)")

    Sqlitex.exec(db, "INSERT INTO x(str) VALUES ('x'),('y'),('z')")

    stmt = Sqlitex.Statement.prepare!(db, "INSERT INTO x(str) VALUES ('x') "
                                          <> ";--RETURNING ON INSERT x,id")

    result = Sqlitex.Statement.fetch_all(stmt, db_timeout: 1_000, into: :raw_list)
    assert result == {:error, {:constraint, 'UNIQUE constraint failed: x.str'}}
  end

  test "custom query timeouts are passed through to esqlite" do
    {:ok, db} = Sqlitex.open(":memory:")

    {:error, reason, _} = catch_throw(
      db
      |> Sqlitex.Statement.prepare!("""
        WITH RECURSIVE r(i) AS (
          VALUES(0)
          UNION ALL
          SELECT i FROM r
          LIMIT 1000000
        )
        SELECT i FROM r WHERE i = 1
      """)
      |> Sqlitex.Statement.fetch_all!(db_timeout: 1)
    )

    assert reason == :timeout
  end
end
