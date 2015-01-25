defmodule SqlitexTest do
  use ExUnit.Case

  test "a basic query returns maps" do
    {:ok, db} = Sqlitex.open('test/fixtures/golfscores.sqlite3')
    [row] = db |> Sqlitex.query("SELECT * FROM players ORDER BY id LIMIT 1")
    assert row == [id: 1, name: "Mikey", created_at: "2012-10-14 05:46:28.318107", updated_at: "2013-09-06 22:29:36.610911", type: :undefined]
    Sqlitex.close(db)
  end

  test "with_db" do
    [row] = Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
      Sqlitex.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
    end)

    assert row = [id: 1, name: "Mikey", created_at: "2012-10-14 05:46:28.318107", updated_at: "2013-09-06 22:29:36.610911", type: :undefined]
  end
end
