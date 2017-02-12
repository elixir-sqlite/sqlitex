defmodule SqlitexTest do
  use ExUnit.Case
  doctest Sqlitex

  @shared_cache 'file::memory:?cache=shared'

  setup_all do
    {:ok, db} = Sqlitex.open(@shared_cache)
    on_exit fn ->
      Sqlitex.close(db)
    end
    {:ok, golf_db: TestDatabase.init(db)}
  end

  test "server basic query" do
    {:ok, conn} = Sqlitex.Server.start_link(@shared_cache)
    {:ok, [row]} = Sqlitex.Server.query(conn, "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318_107}}, updated_at: {{2013,09,06},{22,29,36,610_911}}, type: nil]
    Sqlitex.Server.stop(conn)
  end

  test "server basic query by name" do
    {:ok, _} = Sqlitex.Server.start_link(@shared_cache, name: :sql)
    {:ok, [row]} = Sqlitex.Server.query(:sql, "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318_107}}, updated_at: {{2013,09,06},{22,29,36,610_911}}, type: nil]
    Sqlitex.Server.stop(:sql)
  end

  test "that it returns an error for a bad query" do
    {:ok, _} = Sqlitex.Server.start_link(":memory:", name: :bad_create)
    assert {:error, {:sqlite_error, 'near "WHAT": syntax error'}} == Sqlitex.Server.query(:bad_create, "CREATE WHAT")
  end

  test "a basic query returns a list of keyword lists", context do
    {:ok, [row]} = Sqlitex.query(context[:golf_db], "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318_107}}, updated_at: {{2013,09,06},{22,29,36,610_911}}, type: nil]
  end

  test "a basic query returns a list of maps when into: %{} is given", context do
    {:ok, [row]} = Sqlitex.query(context[:golf_db], "SELECT * FROM players ORDER BY id LIMIT 1", into: %{})
    assert row == %{id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318_107}}, updated_at: {{2013,09,06},{22,29,36,610_911}}, type: nil}
  end

  test "with_db" do
    {:ok, [row]} = Sqlitex.with_db(@shared_cache, fn(db) ->
      Sqlitex.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
    end)

    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28,318_107}}, updated_at: {{2013,09,06},{22,29,36,610_911}}, type: nil]
  end

  test "table creation works as expected" do
    {:ok, [row]} = Sqlitex.with_db(":memory:", fn(db) ->
      Sqlitex.create_table(db, :users, id: {:integer, [:primary_key, :not_null]}, name: :text)
      Sqlitex.query(db, "SELECT * FROM sqlite_master", into: %{})
    end)

    assert row.type == "table"
    assert row.name == "users"
    assert row.tbl_name == "users"
    assert row.sql == "CREATE TABLE \"users\" (\"id\" integer PRIMARY KEY NOT NULL, \"name\" text )"
  end

  test "a parameterized query", context do
    {:ok, [row]} = Sqlitex.query(context[:golf_db], "SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"])
    assert row == [id: 25, name: "Slothstronauts"]
  end

  test "a parameterized query into %{}", context do
    {:ok, [row]} = Sqlitex.query(context[:golf_db], "SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"], into: %{})
    assert row == %{id: 25, name: "Slothstronauts"}
  end

  test "exec" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
    :ok = Sqlitex.exec(db, "INSERT INTO t VALUES (1, 2, 3)")
    {:ok, [row]} = Sqlitex.query(db, "SELECT * FROM t LIMIT 1")
    assert row == [a: 1, b: 2, c: 3]
    Sqlitex.close(db)
  end

  test "it handles queries with no columns" do
    {:ok, db} = Sqlitex.open(':memory:')
    assert {:ok, []} == Sqlitex.query(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
    Sqlitex.close(db)
  end

  test "it handles different cases of column types" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (inserted_at DATETIME, updated_at DateTime)")
    :ok = Sqlitex.exec(db, "INSERT INTO t VALUES ('2012-10-14 05:46:28.312941', '2012-10-14 05:46:35.758815')")
    {:ok, [row]} = Sqlitex.query(db, "SELECT inserted_at, updated_at FROM t")
    assert row[:inserted_at] == {{2012, 10, 14}, {5, 46, 28, 312_941}}
    assert row[:updated_at] == {{2012, 10, 14}, {5, 46, 35, 758_815}}
  end

  test "it inserts nil" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (a INTEGER)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?1)", bind: [nil])
    {:ok, [row]} = Sqlitex.query(db, "SELECT a FROM t")
    assert row[:a] == nil
  end

  test "it inserts boolean values" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (id INTEGER, a BOOLEAN)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?1, ?2)", bind: [1, true])
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?1, ?2)", bind: [2, false])
    {:ok, [row1, row2]} = Sqlitex.query(db, "SELECT a FROM t ORDER BY id")
    assert row1[:a] == true
    assert row2[:a] == false
  end

  test "it inserts Erlang date types" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (d DATE)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?)", bind: [{1985, 10, 26}])
    {:ok, [row]} = Sqlitex.query(db, "SELECT d FROM t")
    assert row[:d] == {1985, 10, 26}
  end

  test "it inserts Elixir time types" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (t TIME)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?)", bind: [{1, 20, 0, 666}])
    {:ok, [row]} = Sqlitex.query(db, "SELECT t FROM t")
    assert row[:t] == {1, 20, 0, 666}
  end

  test "it inserts Erlang datetime tuples" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (dt DATETIME)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?)", bind: [{{1985, 10, 26}, {1, 20, 0, 666}}])
    {:ok, [row]} = Sqlitex.query(db, "SELECT dt FROM t")
    assert row[:dt] == {{1985, 10, 26}, {1, 20, 0, 666}}
  end

  test "query! returns data" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (num INTEGER)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?)", bind: [1])
    results = Sqlitex.query!(db, "SELECT num from t")
    assert results == [[num: 1]]
  end

  test "query! throws on error" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (num INTEGER)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?)", bind: [1])
    assert_raise Sqlitex.QueryError, "Query failed: {:sqlite_error, 'no such column: nope'}", fn ->
      [_res] = Sqlitex.query!(db, "SELECT nope from t")
    end
  end

  test "query_rows returns {:ok, data}", context do
    {:ok, result} = Sqlitex.query_rows(context[:golf_db], "SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"])
    %{rows: rows, columns: columns, types: types} = result
    assert rows == [[25, "Slothstronauts"]]
    assert columns == [:id, :name]
    assert types == [:INTEGER, :"varchar(255)"]
  end

  test "query_rows return {:error, reason}", context do
    {:error, reason} = Sqlitex.query_rows(context[:golf_db], "SELECT wat FROM players")
    assert reason == {:sqlite_error, 'no such column: wat'}
  end

  test "query_rows! returns data", context do
    result = Sqlitex.query_rows!(context[:golf_db], "SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"])
    %{rows: rows, columns: columns, types: types} = result
    assert rows == [[25, "Slothstronauts"]]
    assert columns == [:id, :name]
    assert types == [:INTEGER, :"varchar(255)"]
  end

  test "query_rows! raises on error", context do
    assert_raise Sqlitex.QueryError, "Query failed: {:sqlite_error, 'no such column: wat'}", fn ->
      [_res] = Sqlitex.query_rows!(context[:golf_db], "SELECT wat FROM players")
    end
  end

  test "server query times out" do
    {:ok, conn} = Sqlitex.Server.start_link(":memory:")
    assert match?({:timeout, _},
      catch_exit(Sqlitex.Server.query(conn, "SELECT * FROM sqlite_master", timeout: 0)))
    receive do # wait for the timed-out message
      msg -> msg
    end
  end

  test "decimal types" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (f DECIMAL)")
    d = Decimal.new(1.123)
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?)", bind: [d])
    {:ok, [row]} = Sqlitex.query(db, "SELECT f FROM t")
    assert row[:f] == d
  end

  test "decimal types with scale and precision" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (id INTEGER, f DECIMAL(3,2))")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?,?)", bind: [1, Decimal.new(1.123)])
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?,?)", bind: [2, Decimal.new(244.37)])
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?,?)", bind: [3, Decimal.new(1997)])

    # results should be truncated to the appropriate precision and scale:
    Sqlitex.query!(db, "SELECT f FROM t ORDER BY id")
    |> Enum.map(fn row -> row[:f] end)
    |> Enum.zip([Decimal.new(1.12), Decimal.new(244), Decimal.new(1990)])
    |> Enum.each(fn {res, ans} -> assert Decimal.equal?(res, ans) end)
  end

  test "it handles datetime, date, time with empty string" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (a datetime NOT NULL, b date NOT NULL, c time NOT NULL)")
    {:ok, []} = Sqlitex.query(db, "INSERT INTO t VALUES (?, ?, ?)", bind: ["", "", ""])
    {:ok, [row]} = Sqlitex.query(db, "SELECT a, b, c FROM t")
    assert row[:a] == nil
    assert row[:b] == nil
    assert row[:c] == nil
  end
end
