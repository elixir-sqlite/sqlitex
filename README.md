[![CircleCI](https://circleci.com/gh/Sqlite-Ecto/sqlitex.svg?style=svg)](https://circleci.com/gh/Sqlite-Ecto/sqlitex)
[![Coverage Status](https://coveralls.io/repos/github/Sqlite-Ecto/sqlitex/badge.svg?branch=master)](https://coveralls.io/github/Sqlite-Ecto/sqlitex?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/sqlitex.svg)](https://hex.pm/packages/sqlitex)
[![Hex.pm](https://img.shields.io/hexpm/dt/sqlitex.svg)](https://hex.pm/packages/sqlitex)

# Sqlitex

An Elixir wrapper around [esqlite](https://github.com/mmzeeman/esqlite). The main aim here is to provide convenient usage of SQLite databases.

# Updated to 1.0

With the 1.0 release, we made just a single breaking change. `Sqlitex.Query.query` previously returned just the raw query results on success and `{:error, reason}` on failure.
This has been bothering us for a while, so we changed it in 1.0 to return `{:ok, results}` on success and `{:error, reason}` on failure.
This should make it easier to pattern match on. The `Sqlitex.Query.query!` function has kept its same functionality of returning bare results on success and raising an error on failure.

# Usage

The simple way to use `sqlitex` is just to open a database and run a query:

```elixir
Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
  Sqlitex.query(db, "SELECT * FROM players ORDER BY id LIMIT 1")
end)
# => [[id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]]

Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
  Sqlitex.query(db, "SELECT * FROM players ORDER BY id LIMIT 1", into: %{})
end)
# => [%{id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil}]
```

Pass the `bind` option to bind parameterized queries.

```elixir
Sqlitex.with_db('test/fixtures/golfscores.sqlite3', fn(db) ->
  Sqlitex.query(
    db,
    "INSERT INTO players (name, created_at, updated_at) VALUES (?1, ?2, ?3, ?4)",
    bind: ['Mikey', '2012-10-14 05:46:28.318107', '2013-09-06 22:29:36.610911']
  )
end)
# => [[id: 1, name: "Mikey", created_at: {{2012,10,14},{05,46,28}}, updated_at: {{2013,09,06},{22,29,36}}, type: nil]]
```

If you want to keep the database open during the lifetime of your project, you can use the `Sqlitex.Server` GenServer module.
Here's a sample from a phoenix projects main supervisor definition.

```elixir
children = [
  # Start the endpoint when the application starts
  worker(Golf.Endpoint, []),
  worker(Sqlitex.Server, ['golf.sqlite3', [name: Golf.DB]])
]
```

Now that the GenServer is running you can make queries via
```elixir
Sqlitex.Server.query(Golf.DB,
                     "SELECT g.id, g.course_id, g.played_at, c.name AS course
                      FROM games AS g
                      INNER JOIN courses AS c ON g.course_id = c.id
                      ORDER BY g.played_at DESC LIMIT 10")
```

# Looking for Ecto?
Check out the [SQLite Ecto2 adapter](https://github.com/Sqlite-Ecto/sqlite_ecto2)
