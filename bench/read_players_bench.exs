defmodule ReadPlayersBench do
  use Benchfella

  bench "read players into keyword lists" do
    Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
      db |> Sqlitex.query("SELECT * FROM players", into: [])
    end)
  end

  bench "read players into maps" do
    Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
      db |> Sqlitex.query("SELECT * FROM players", into: %{})
    end)
  end
end
