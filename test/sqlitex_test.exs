defmodule SqlitexTest do
  use ExUnit.Case

  test "a basic query returns a list of keyword lists" do
    {:ok, db} = Sqlitex.open('test/fixtures/golfscores.sqlite3')
    [row] = db |> Sqlitex.query("SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]
    Sqlitex.close(db)
  end

  test "a basic query returns a list of maps when into: %{} is given" do
    {:ok, db} = Sqlitex.open('test/fixtures/golfscores.sqlite3')
    [row] = db |> Sqlitex.query("SELECT * FROM players ORDER BY id LIMIT 1", into: %{})
    assert row == %{id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil}
    Sqlitex.close(db)
  end

  test "with_db" do
    [row] = Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
      Sqlitex.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
    end)

    assert row == [id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]
  end

  test "a parameterized query" do
    {:ok, db} = Sqlitex.open('test/fixtures/golfscores.sqlite3')
    [row] = db |> Sqlitex.query("SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"])
    assert row == [id: 25, name: "Slothstronauts"]
    Sqlitex.close(db)
  end

  test "a parameterized query into %{}" do
    {:ok, db} = Sqlitex.open('test/fixtures/golfscores.sqlite3')
    [row] = db |> Sqlitex.query("SELECT id, name FROM players WHERE name LIKE ?1 AND type == ?2", bind: ["s%", "Team"], into: %{})
    assert row == %{id: 25, name: "Slothstronauts"}
    Sqlitex.close(db)
  end

  test "exec" do
    {:ok, db} = Sqlitex.open(':memory:')
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
