defmodule Sqlitex.SqlBuilder do
  @moduledoc """
  This module contains functions for SQL creation. At the moment
  it is only used for `CREATE TABLE` statements.
  """

  # Returns an SQL CREATE TABLE statement as a string. `name` is the name of the
  # table, and `table_opts` contains the table constraints (at the moment only
  # PRIMARY KEY is supported). `cols` is expected to be a keyword list in the
  # form of:
  #
  # column_name: :column_type, of
  # column_name: {:column_type, [column_constraints]}
  def create_table(name, table_opts, cols) do
    tbl_options = get_opts_map(table_opts, &table_opt/1)
    get_opt = &(Map.get(tbl_options, &1, nil))

    "CREATE #{get_opt.(:temp)} TABLE \"#{name}\" (#{get_columns_block(cols)} #{get_opt.(:primary_key)})"
  end

  # Supported table options
  defp table_opt(:temporary), do: {:temp, "TEMP"}
  defp table_opt(:temp), do: {:temp, "TEMP"}
  defp table_opt({:primary_key, cols}) when is_list(cols) do
    {
      :primary_key, ",PRIMARY KEY ("
      # Also quote the columns in a PRIMARY KEY list
      <> (cols |> Enum.map(&(~s("#{&1}"))) |> Enum.join(","))
      <> ")"
    }
  end
  defp table_opt({:primary_key, col}) when is_atom(col) do
    {:primary_key, ",PRIMARY KEY (\"" <> Atom.to_string(col) <> "\")"}
  end

  # Supported column options
  defp column_opt(:primary_key), do: {:primary_key, "PRIMARY KEY"}
  defp column_opt(:not_null), do: {:not_null, "NOT NULL"}
  defp column_opt(:autoincrement), do: {:autoincrement, "AUTOINCREMENT"}

  # Helper function that creates a map of option names
  # and their string representations
  defp get_opts_map(opts, opt) do
    Enum.into(opts, %{}, &(opt.(&1)))
  end

  # Create the sql fragment for the column definitions from the
  # passed keyword list
  defp get_columns_block(cols) do
    Enum.map_join(cols, ", ", fn(col) ->
      case col do
        # Column with name, type and constraint
        {name, {type, constraints}} ->
          col_options = get_opts_map(constraints, &column_opt/1)
          get_opt = &(Map.get(col_options, &1, nil))

          [~s("#{name}"), type, get_opt.(:primary_key), get_opt.(:not_null), get_opt.(:autoincrement)]
            |> Enum.filter(&(&1))
            |> Enum.join(" ")
        # Column with name and type
        {name, type} ->
          ~s("#{name}" #{type})
      end
    end)
  end
end
