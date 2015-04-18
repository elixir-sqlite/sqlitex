defmodule Sqlitex do
  def close(db) do
    :esqlite3.close(db)
  end

  def open(path) when is_binary(path), do: open(String.to_char_list(path))
  def open(path) do
    :esqlite3.open(path)
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end

  def exec(db, sql) do
    :esqlite3.exec(sql, db)
  end

  def query(db, sql, opts \\ []) do
    {params, into} = query_options(opts)
    {:ok, statement} = :esqlite3.prepare(sql, db)
    :ok = :esqlite3.bind(statement, params)
    types = :esqlite3.column_types(statement)
    columns = :esqlite3.column_names(statement)
    rows = :esqlite3.fetchall(statement)
    return_rows_or_error(types, columns, rows, into)
  end

  defp query_options(opts) do
    params = Keyword.get(opts, :bind, [])
    into = Keyword.get(opts, :into, [])
    {params, into}
  end

  defp return_rows_or_error(_, _, {:error, _} = error, _), do: error
  defp return_rows_or_error({:error, :no_columns}, columns, rows, into), do: return_rows_or_error({}, columns, rows, into)
  defp return_rows_or_error({:error, _} = error, _columns, _rows, _into), do: error
  defp return_rows_or_error(types, {:error, :no_columns}, rows, into), do: return_rows_or_error(types, {}, rows, into)
  defp return_rows_or_error(_types, {:error, _} = error, _rows, _into), do: error
  defp return_rows_or_error(types, columns, rows, into) do
    Sqlitex.Row.from(Tuple.to_list(types), Tuple.to_list(columns), rows, into)
  end
end
