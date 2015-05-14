defmodule SqlitexTest do
  use ExUnit.Case

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
    [row] = Sqlitex.Server.query(conn, "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]
    Sqlitex.Server.stop(conn)
  end

  test "server basic query by name" do
    {:ok, _} = Sqlitex.Server.start_link(@shared_cache, name: :sql)
    [row] = Sqlitex.Server.query(:sql, "SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]
    Sqlitex.Server.stop(:sql)
  end

  test "a basic query returns a list of keyword lists", context do
    [row] = context[:golf_db] |> Sqlitex.query("SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]
  end

  test "a basic query returns a list of maps when into: %{} is given", context do
    [row] = context[:golf_db] |> Sqlitex.query("SELECT * FROM players ORDER BY id LIMIT 1", into: %{})
    assert row == %{id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil}
  end

  test "with_db" do
    [row] = Sqlitex.with_db(@shared_cache, fn(db) ->
      Sqlitex.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
    end)

    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]
  end

  test "table creation works as expected" do
    [row] = Sqlitex.with_db(":memory:", fn(db) ->
      Sqlitex.create_table(db, :users, id: {:integer, [:primary_key, :not_null]}, name: :text)
      Sqlitex.query(db, "SELECT * FROM sqlite_master", into: %{})
    end)

    assert row.type == "table"
    assert row.name == "users"
    assert row.tbl_name == "users"
    assert row.sql == "CREATE TABLE \"users\" (\"id\" integer PRIMARY KEY NOT NULL, \"name\" text )"
  end

  test "a parameterized query", context do
    [row] = context[:golf_db] |> Sqlitex.query("SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"])
    assert row == [id: 25, name: "Slothstronauts"]
  end

  test "a parameterized query into %{}", context do
    [row] = context[:golf_db] |> Sqlitex.query("SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"], into: %{})
    assert row == %{id: 25, name: "Slothstronauts"}
  end

  test "exec" do
    {:ok, db} = Sqlitex.open(":memory:")
    :ok = Sqlitex.exec(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
    :ok = Sqlitex.exec(db, "INSERT INTO t VALUES (1, 2, 3)")
    [row] = Sqlitex.query(db, "SELECT * FROM t LIMIT 1")
    assert row == [a: 1, b: 2, c: 3]
    Sqlitex.close(db)
  end

  test "it handles queries with no columns" do
    {:ok, db} = Sqlitex.open(':memory:')
    assert [] == Sqlitex.query(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
    Sqlitex.close(db)
  end
end
