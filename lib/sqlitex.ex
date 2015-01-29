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
      values = row |> Tuple.to_list |> Enum.map(&translate_value/1)
      Enum.zip(columns,values)
    end)
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end

  defp translate_value(str) when is_binary(str) do
    case Regex.run(~r<\A(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}).\d{6}\Z>, str) do
      [_s,yrs,mos,das,hrs,mns,ss] ->
        [yr,mo,da,hr,mn,s] = [yrs,mos,das,hrs,mns,ss] |> Enum.map(&String.to_integer/1)
        {{yr,mo,da},{hr,mn,s}}
      nil ->
        str
    end
  end
  defp translate_value(:undefined) do
    nil
  end
  defp translate_value(val) do
    val
  end
end
