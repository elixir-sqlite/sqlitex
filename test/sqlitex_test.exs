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
    [row] = db |> Sqlitex.query("SELECT id, name FROM players WHERE name LIKE ? AND type == ?", ["s%", "Team"])
    assert row == [id: 25, name: "Slothstronauts"]
    Sqlitex.close(db)
  end

  test "a parameterized query into %{}" do
    {:ok, db} = Sqlitex.open('test/fixtures/golfscores.sqlite3')
    [row] = db |> Sqlitex.query("SELECT id, name FROM players WHERE name LIKE ? AND type == ?", ["s%", "Team"], into: %{})
    assert row == %{id: 25, name: "Slothstronauts"}
    Sqlitex.close(db)
  end
end
