defmodule Sqlitex do
  def close(db) do
    :esqlite3.close(db)
  end

  def open(path) do
    :esqlite3.open(path)
  end

  def query(db, sql) do
    do_query(db, sql, nil, [])
  end
  def query(db, sql, into: into) do
    do_query(db, sql, nil, into)
  end
  def query(db, sql, params) when is_list(params) do
    do_query(db, sql, params, [])
  end
  def query(db, sql, params, into: into) when is_list(params) do
    do_query(db, sql, params, into)
  end

  defp do_query(db, sql, params, into) do
    {:ok, statement} = :esqlite3.prepare(sql, db)
    if params do
      :ok = :esqlite3.bind(statement, params)
    end
    types = :esqlite3.column_types(statement) |> Tuple.to_list
    columns = :esqlite3.column_names(statement) |> Tuple.to_list
    rows = :esqlite3.fetchall(statement)
    Sqlitex.Row.from(types, columns, rows, into)
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end
end
