defmodule Sqlitex do
  def close(db) do
    :esqlite3.close(db)
  end

  def open(path) do
    :esqlite3.open(path)
  end

  def query(db, query) do
    {:ok, statement} = :esqlite3.prepare(query, db)
    columns = :esqlite3.column_names(statement) |> Tuple.to_list
    rows = :esqlite3.fetchall(statement)
    Enum.map(rows, fn(row) ->
      Enum.zip(columns,Tuple.to_list(row))
    end)
  end
end
