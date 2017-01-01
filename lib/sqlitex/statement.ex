defmodule Sqlitex.Statement do
  alias Sqlitex.Row
  @moduledoc """
  Provides an interface for working with sqlite prepared statements.

  Care should be taken when using prepared statements directly - they are not
  immutable objects like most things in Elixir. Sharing a statement between
  different processes can cause problems if the processes accidentally
  interleave operations on the statement. It's a good idea to create different
  statements per process, or to wrap the statements up in a GenServer to prevent
  interleaving operations.

  ## Example

  ```
  iex(2)> {:ok, db} = Sqlitex.open(":memory:")
  iex(3)> Sqlitex.query(db, "CREATE TABLE data (id, name);")
  {:ok, []}
  iex(4)> {:ok, statement} = Sqlitex.Statement.prepare(db, "INSERT INTO data VALUES (?, ?);")
  iex(5)> Sqlitex.Statement.bind_values(statement, [1, "hello"])
  iex(6)> Sqlitex.Statement.exec(statement)
  :ok
  iex(7)> {:ok, statement} = Sqlitex.Statement.prepare(db, "SELECT * FROM data;")
  iex(8)> Sqlitex.Statement.fetch_all(statement)
  {:ok, [[id: 1, name: "hello"]]}
  iex(9)> Sqlitex.close(db)
  :ok

  ```
  """

  defstruct database: nil,
            statement: nil,
            column_names: [],
            column_types: []

  @doc """
  Prepare a Sqlitex.Statement

  ## Parameters

  * `db` - The database to prepare the statement for.
  * `sql` - The SQL of the statement to prepare.

  ## Returns

  * `{:ok, statement}` on success
  * See `:esqlite3.prepare` for errors.
  """
  def prepare(db, sql) do
    with {:ok, db} <- do_prepare(db, sql),
         {:ok, db} <- get_column_names(db),
         {:ok, db} <- get_column_types(db),
    do: {:ok, db}
  end

  @doc """
  Same as `prepare/2` but raises a Sqlitex.Statement.PrepareError on error.

  Returns a new statement otherwise.
  """
  def prepare!(db, sql) do
    case prepare(db, sql) do
      {:ok, statement} -> statement
      {:error, reason} -> raise Sqlitex.Statement.PrepareError, reason: reason
    end
  end

  @doc """
  Binds values to a Sqlitex.Statement

  ## Parameters

  * `statement` - The statement to bind values into.
  * `values` - A list of values to bind into the statement.

  ## Returns

  * `{:ok, statement}` on success
  * See `:esqlite3.prepare` for errors.

  ## Value transformations

  Some values will be transformed before insertion into the database.

  * `nil` - Converted to :undefined
  * `true` - Converted to 1
  * `false` - Converted to 0
  * `datetime` - Converted into a string.  See datetime_to_string
  * `%Decimal` -  Converted into a number.
  """
  def bind_values(statement, values) do
    case :esqlite3.bind(statement.statement, translate_bindings(values)) do
      {:error, _} = error -> error
      :ok -> {:ok, statement}
    end
  end

  @doc """
  Same as `bind_values/2` but raises a Sqlitex.Statement.BindValuesError on error.

  Returns the statement otherwise.
  """
  def bind_values!(statement, values) do
    case bind_values(statement, values) do
      {:ok, statement} -> statement
      {:error, reason} -> raise Sqlitex.Statement.BindValuesError, reason: reason
    end
  end

  @doc """
  Fetches all rows using a statement.

  Should be called after the statement has been bound.

  ## Parameters

  * `statement` - The statement to run.
  * `into` - The collection to put the results into. Defaults to an empty list.

  ## Returns

  * `{:ok, results}`
  * `{:ok, results, column_names}` if `into: :raw_list`
  * `{:error, error}`
  """
  def fetch_all(statement, into \\ [], include_types? \\ false) do
    column_names = statement.column_names
    column_types = statement.column_types
    case :esqlite3.fetchall(statement.statement) do
      {:error, _} = other -> other
      raw_data ->
        {:ok, Row.from(column_types, column_names, raw_data, into)} |>
          maybe_add_column_info(column_names, into, column_types, include_types?)
    end
  end

  defp maybe_add_column_info({:ok, rows}, column_names, :raw_list, column_types, true) do
    {:ok, rows, column_names, column_types}
  end
  defp maybe_add_column_info({:ok, rows}, column_names, :raw_list, column_types, false) do
    {:ok, rows, column_names}
  end
  defp maybe_add_column_info(result, _, _, _, _), do: result

  @doc """
  Same as `fetch_all/2` but raises a Sqlitex.Statement.FetchAllError on error.

  Returns the results otherwise.
  """
  def fetch_all!(statement, into \\ []) do
    case fetch_all(statement, into) do
      {:ok, results} -> results
      {:error, reason} -> raise Sqlitex.Statement.FetchAllError, reason: reason
    end
  end

  @doc """
  Runs a statement that returns no results.

  Should be called after the statement has been bound.

  ## Parameters

  * `statement` - The statement to run.

  ## Returns

  * `:ok`
  * `{:error, error}`
  """
  def exec(statement) do
    case :esqlite3.step(statement.statement) do
      # esqlite3.step returns some odd values, so lets translate them:
      :"$done" -> :ok
      :"$busy" -> {:error, {:busy, "Sqlite database is busy"}}
      other -> other
    end
  end

  @doc """
  Same as `exec/1` but raises a Sqlitex.Statement.ExecError on error.

  Returns :ok otherwise.
  """
  def exec!(statement) do
    case exec(statement) do
      :ok -> :ok
      {:error, reason} -> raise Sqlitex.Statement.ExecError, reason: reason
    end
  end

  defp do_prepare(db, sql) do
    case :esqlite3.prepare(sql, db) do
      {:ok, statement} ->
        {:ok, %Sqlitex.Statement{database: db, statement: statement}}
      other -> other
    end
  end

  defp get_column_names(%Sqlitex.Statement{statement: sqlite_statement} = statement) do
    names =
      sqlite_statement
      |> :esqlite3.column_names
      |> Tuple.to_list
    {:ok, %Sqlitex.Statement{statement | column_names: names}}
  end

  defp get_column_types(%Sqlitex.Statement{statement: sqlite_statement} = statement) do
    types =
      sqlite_statement
      |> :esqlite3.column_types
      |> Tuple.to_list
    {:ok, %Sqlitex.Statement{statement | column_types: types}}
  end

  defp translate_bindings(params) do
    Enum.map(params, fn
      nil -> :undefined
      true -> 1
      false -> 0
      date = {_yr, _mo, _da} -> date_to_string(date)
      time = {_hr, _mi, _se, _usecs} -> time_to_string(time)
      datetime = {{_yr, _mo, _da}, {_hr, _mi, _se, _usecs}} -> datetime_to_string(datetime)
      %Decimal{sign: sign, coef: coef, exp: exp} -> sign * coef * :math.pow(10, exp)
      other -> other
    end)
  end

  defp date_to_string({yr, mo, da}) do
    Enum.join [zero_pad(yr, 4), "-", zero_pad(mo, 2), "-", zero_pad(da, 2)]
  end

  def time_to_string({hr, mi, se, usecs}) do
    Enum.join [zero_pad(hr, 2), ":", zero_pad(mi, 2), ":", zero_pad(se, 2), ".", zero_pad(usecs, 6)]
  end

  defp datetime_to_string({date = {_yr, _mo, _da}, time = {_hr, _mi, _se, _usecs}}) do
    Enum.join [date_to_string(date), " ", time_to_string(time)]
  end

  defp zero_pad(num, len) do
    str = Integer.to_string num
    String.duplicate("0", len - String.length(str)) <> str
  end
end
