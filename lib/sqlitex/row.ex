defmodule Sqlitex.Row do
  def from(types, columns, rows, into) do
    for row <- rows do
      build_row(types, columns, row, into)
    end
  end

  defp build_row(types, columns, row, into) do
    values = row |> Tuple.to_list |> Enum.zip(types) |> Enum.map(&translate_value/1)

    columns
      |> Enum.zip(values)
      |> Enum.into(into)
  end

  defp translate_value({str, :datetime}) do
    <<yr::binary-size(4), "-", mo::binary-size(2), "-", da::binary-size(2), " ", hr::binary-size(2), ":", mi::binary-size(2), ":", se::binary-size(2), ".", _fr::binary-size(6)>> = str
    {{String.to_integer(yr), String.to_integer(mo), String.to_integer(da)},{String.to_integer(hr), String.to_integer(mi), String.to_integer(se)}}
  end

  defp translate_value({:undefined,_type}) do
    nil
  end

  defp translate_value({val, _type}) do
    val
  end
end
