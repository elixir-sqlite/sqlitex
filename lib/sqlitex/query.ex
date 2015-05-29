defmodule Sqlitex.Query do
  use Pipe

  defstruct bindings: [],
            column_names: [],
            column_types: [],
            database: nil,
            into: [],
            raw_data: [],
            sql: nil,
            statement: nil

  def query(db, sql, opts \\ []) do
    pipe_matching {:ok, _},
      {:ok, %Sqlitex.Query{bindings: bindings_from_opts(opts), into: into_from_opts(opts), database: db, sql: sql}}
        |> prepare
        |> bind_values
        |> column_types
        |> column_names
        |> fetch_data
        |> into_rows
  end

  defp bind_values({:ok, %Sqlitex.Query{bindings: bindings, statement: statement}=query}) do
    case :esqlite3.bind(statement, bindings) do
      {:error,_}=error -> error
      :ok -> {:ok, query}
    end
  end

  defp bindings_from_opts(opts), do: opts |> Keyword.get(:bind, []) |> translate_bindings

  defp column_names({:ok, %Sqlitex.Query{statement: statement}=query}) do
    case :esqlite3.column_names(statement) do
      {:error, :no_columns} -> {:ok, %Sqlitex.Query{query | column_names: {}}}
      {:error, _}=other -> other
      names -> {:ok, %Sqlitex.Query{query | column_names: names}}
    end
  end

  defp column_types({:ok, %Sqlitex.Query{statement: statement}=query}) do
    case :esqlite3.column_types(statement) do
      {:error, :no_columns} -> {:ok, %Sqlitex.Query{query | column_types: {}}}
      {:error, _}=other -> other
      types -> {:ok, %Sqlitex.Query{query | column_types: types}}
    end
  end

  defp datetime_to_string({{yr, mo, da}, {hr, mi, se, usecs}}) do
    [zero_pad(yr, 4), "-", zero_pad(mo, 2), "-", zero_pad(da, 2), " ", zero_pad(hr, 2), ":", zero_pad(mi, 2), ":", zero_pad(se, 2), ".", zero_pad(usecs, 6)]
    |> Enum.join
  end

  defp fetch_data({:ok, %Sqlitex.Query{statement: statement}=query}) do
    case :esqlite3.fetchall(statement) do
      {:error,_}=other -> other
      raw_data -> {:ok, %Sqlitex.Query{query | raw_data: raw_data}}
    end
  end

  defp into_from_opts(opts), do: Keyword.get(opts, :into, [])

  defp prepare({:ok, %Sqlitex.Query{sql: sql, database: database}=query}) do
    case :esqlite3.prepare(sql, database) do
      {:ok, statement} -> {:ok, %Sqlitex.Query{query | statement: statement}}
      other -> other
    end
  end

  defp into_rows({:ok, %Sqlitex.Query{column_types: types, column_names: names, raw_data: raw_data, into: into}}) do
    Sqlitex.Row.from(Tuple.to_list(types), Tuple.to_list(names), raw_data, into)
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
