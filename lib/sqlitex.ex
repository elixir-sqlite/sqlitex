defmodule Sqlitex do
  def close(db) do
    :esqlite3.close(db)
  end

  def open(path) do
    :esqlite3.open(path)
  end

  def exec(db, query) do
    :esqlite3.exec(query, db)
  end

  def query(db, query, opts \\ []) do
    {:ok, statement} = :esqlite3.prepare(query, db)
    types = :esqlite3.column_types(statement) |> Tuple.to_list
    columns = :esqlite3.column_names(statement) |> Tuple.to_list
    rows = :esqlite3.fetchall(statement)
    into = Keyword.get(opts, :into, [])
    Sqlitex.Row.from(types, columns, rows, into)
  end

  def create(db, name, rows) do
    stmt = Enum.reduce(rows, nil, fn row, acc ->
      {name, type} = row
      cond do
        acc == nil ->
          Enum.join([Atom.to_string(name), Atom.to_string(type)], " ")
        true ->
          Enum.join([acc, ",", Atom.to_string(name), Atom.to_string(type)], " ")
      end
    end)

    exec(db, "CREATE TABLE IF NOT EXISTS #{name} (#{stmt})")
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end
end
