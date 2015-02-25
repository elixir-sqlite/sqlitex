[![Build Status](https://travis-ci.org/mmmries/sqlitex.svg?branch=master)](https://travis-ci.org/mmmries/sqlitex)

Sqlitex
=======

An Elixir wrapper around [https://github.com/mmzeeman/esqlite](esqlite). The main aim here is to provide convenient usage of sqlite databases.

Usage
=====

The simples way to use sqlitex is just to open a database and run a query

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

If you want to keep the database open during the lifetime of your project you can use the `Sqlitex.Server` GenServer module.
Here's a sample from a phoenix projects main supervisor definition.
```elixir
children = [
      # Start the endpoint when the application starts
      worker(Golf.Endpoint, []),

      worker(Sqlitex.Server, ['/Users/hqmq/code/golfscore-phoenix/db/golf.sqlite3'])
    ]
```

Now that the GenServer is running you can make queries via
```elixir
Sqlitex.Server.query("SELECT g.id, g.course_id, g.played_at, c.name AS course
                      FROM games AS g
                      INNER JOIN courses AS c ON g.course_id = c.id
                      ORDER BY g.played_at DESC LIMIT 10")
```

Benchmarks
==========

I'm using [Benchfella](https://github.com/alco/benchfella) to keep track of our performance for some of the basic operations. If you want to check benchmark speeds just install benchfella and then run `mix bench` to run the stats.

Plans
=====

This package currently only supports really basic reads. I am building this package as an attempt to learn more about Elixir and I'll be adding features only as I need them.

I would love to get any feedback I can on how other people might want to use SQlite with Elixir.
