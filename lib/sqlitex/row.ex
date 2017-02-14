defmodule Sqlitex.Row do
  def from(types, columns, rows, into) do
    for row <- rows do
      build_row(types, columns, row, into)
    end
  end

  defp build_row(_types, _columns, row, :raw_list) do
    Tuple.to_list(row)
  end
  defp build_row(types, columns, row, into) do
    types = Enum.map(types, fn type ->
      type |> Atom.to_string |> String.downcase
    end)
    values = row |> Tuple.to_list |> Enum.zip(types) |> Enum.map(&translate_value/1)

    columns
      |> Enum.zip(values)
      |> Enum.into(into)
  end

  ## Convert SQLite values/types to Elixir types

  defp translate_value({:undefined, _type}) do
    nil
  end

  # date is empty ""
  defp translate_value({"", "date"}), do: nil

  defp translate_value({date, "date"}) when is_binary(date), do: to_date(date)

  # time is empty ""
  defp translate_value({"", "time"}), do: nil

  defp translate_value({time, "time"}) when is_binary(time), do: to_time(time)

  # datetime is empty ""
  defp translate_value({"", "datetime"}), do: nil

  # datetime format is "YYYY-MM-DD HH:MM:SS.FFFFFF"
  defp translate_value({datetime, "datetime"}) when is_binary(datetime) do
    [date, time] = String.split(datetime)
    {to_date(date), to_time(time)}
  end

  defp translate_value({0, "boolean"}), do: false
  defp translate_value({1, "boolean"}), do: true

  defp translate_value({int, type = <<"decimal", _::binary>>}) when is_integer(int) do
    {result, _} = int |> Integer.to_string |> Float.parse
    translate_value({result, type})
  end
  defp translate_value({float, "decimal"}), do: Decimal.new(float)
  defp translate_value({float, "decimal(" <> rest}) do
    [precision, scale] = rest |> String.rstrip(?)) |> String.split(",") |> Enum.map(&String.to_integer/1)
    Decimal.with_context %Decimal.Context{precision: precision, rounding: :down}, fn ->
      float |> Float.round(scale) |> Decimal.new |> Decimal.plus
    end
  end

  defp translate_value({val, _type}) do
    val
  end

  defp to_date(date) do
    <<yr::binary-size(4), "-", mo::binary-size(2), "-", da::binary-size(2)>> = date
    {String.to_integer(yr), String.to_integer(mo), String.to_integer(da)}
  end

  defp to_time(<<hr::binary-size(2), ":", mi::binary-size(2)>>) do
    {String.to_integer(hr), String.to_integer(mi), 0, 0}
  end
  defp to_time(<<hr::binary-size(2), ":", mi::binary-size(2), ":", se::binary-size(2)>>) do
    {String.to_integer(hr), String.to_integer(mi), String.to_integer(se), 0}
  end
  defp to_time(<<hr::binary-size(2), ":", mi::binary-size(2), ":", se::binary-size(2), ".", fr::binary>>) when byte_size(fr) <= 6 do
    fr = String.to_integer(fr <> String.duplicate("0", 6 - String.length(fr)))
    {String.to_integer(hr), String.to_integer(mi), String.to_integer(se), fr}
  end
end
