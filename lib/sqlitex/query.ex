defmodule Sqlitex.Query do
  use Pipe

  def query(db, sql, opts \\ []) do
    pipe_matching {:ok, _},
        prepare(sql, db)
        |> bind_values(opts)
        |> execute(opts)
  end

  defp bind_values({:ok, statement}, opts) do
    params = params_from_opts(opts)
    case :esqlite3.bind(statement, params) do
      {:error,_}=error -> error
      :ok -> {:ok, statement}
    end
  end

  defp datetime_to_string({{yr, mo, da}, {hr, mi, se, usecs}}) do
    [zero_pad(yr, 4), "-", zero_pad(mo, 2), "-", zero_pad(da, 2), " ", zero_pad(hr, 2), ":", zero_pad(mi, 2), ":", zero_pad(se, 2), ".", zero_pad(usecs, 6)]
    |> Enum.join
  end

  defp execute({:ok, statement}, opts) do
    into = into_from_opts(opts)
    types = :esqlite3.column_types(statement)
    columns = :esqlite3.column_names(statement)
    data = :esqlite3.fetchall(statement)
    to_rows(types, columns, data, into)
  end

  defp into_from_opts(opts), do: Keyword.get(opts, :into, [])

  defp params_from_opts(opts), do: opts |> Keyword.get(:bind, []) |> translate_bindings

  defp prepare(sql, database), do: :esqlite3.prepare(sql, database)

  defp to_rows(_,_,{:error,_}=error,_), do: error
  defp to_rows({:error, :no_columns}, columns, rows, into), do: to_rows({}, columns, rows, into)
  defp to_rows({:error, _}=error, _columns, _rows, _into), do: error
  defp to_rows(types, {:error, :no_columns}, rows, into), do: to_rows(types, {}, rows, into)
  defp to_rows(_types, {:error, _}=error, _rows, _into), do: error
  defp to_rows(types, columns, rows, into) do
    Sqlitex.Row.from(Tuple.to_list(types), Tuple.to_list(columns), rows, into)
  end

  defp translate_bindings(params) do
    Enum.map(params, fn
      nil -> :undefined
      true -> 1
      false -> 0
      datetime={{_yr, _mo, _da}, {_hr, _mi, _se, _usecs}} -> datetime_to_string(datetime)
      other -> other
    end)
  end

  defp zero_pad(num, len) do
    str = Integer.to_string num
    String.duplicate("0", len - String.length(str)) <> str
  end
end
