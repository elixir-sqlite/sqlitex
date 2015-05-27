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
    case :esqlite3.prepare(sql, db) do
      {:ok, statement} -> bind_and_query(statement, opts)
      {:error, _}=error -> error
    end
  end

  @doc """
  Create a new table `name` where `table_opts` are a list of table constraints
  and `cols` are a keyword list of columns. The following table constraints are
  supported: `:temp` and `:primary_key`. Example:

  **[:temp, {:primary_key, [:id]}]**

  Columns can be passed as:
  * name: :type
  * name: {:type, constraints}

  where constraints is a list of column constraints. The following column constraints
  are supported: `:primary_key`, `:not_null` and `:autoincrement`. Example:

  **id: :integer, name: {:text, [:not_null]}**

  """
  def create_table(db, name, table_opts \\ [], cols) do
    stmt = Sqlitex.SqlBuilder.create_table(name, table_opts, cols)
    exec(db, stmt)
  end

  defp bind_and_query(statement, opts) do
    {params, into} = query_options(opts)
    case :esqlite3.bind(statement, params) do
      {:error, _}=error -> error
      :ok ->
        types = :esqlite3.column_types(statement)
        columns = :esqlite3.column_names(statement)
        rows = :esqlite3.fetchall(statement)
        return_rows_or_error(types, columns, rows, into)
    end
  end

  defp query_options(opts) do
    params = opts |> Keyword.get(:bind, []) |> translate_bindings
    into = Keyword.get(opts, :into, [])
    {params, into}
  end

  defp translate_bindings(params) do
    Enum.map(params, fn
      nil -> :undefined
      true -> 1
      false -> 0
      {{_yr, _mo, _da}, {_hr, _mi, _se}}=datetime -> datetime_to_string(datetime)
      {{yr, mo, da}, {hr, mi, se, _usecs}} -> datetime_to_string({{yr, mo, da}, {hr, mi, se}})
      other -> other
    end)
  end

  # Translate the given Erlang datetime tuple to an appropriate string for
  # SQLite.  Microseconds are zeroed.
  defp datetime_to_string({{yr, mo, da}, {hr, mi, se}}) do
    [zero_pad(yr, 4), "-", zero_pad(mo, 2), "-", zero_pad(da, 2), " ", zero_pad(hr, 2), ":", zero_pad(mi, 2), ":", zero_pad(se, 2), ".000000"]
    |> Enum.join
  end

  defp zero_pad(num, len) do
    str = Integer.to_string num
    String.duplicate("0", len - String.length(str)) <> str
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
