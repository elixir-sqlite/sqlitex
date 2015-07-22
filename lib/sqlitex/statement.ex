defmodule Sqlitex.Statement do
  @moduledoc """
  Provides an interface for working with sqlite prepared statements.

  ```
  iex(2)> {:ok, db} = Sqlitex.open(":memory:")
  iex(3)> Sqlitex.query(db, "CREATE TABLE data (id, name);")
  []
  iex(6)> {:ok, statement} = Sqlitex.Statement.prepare(db, "INSERT INTO data VALUES (?, ?);")
  iex(7)> Sqlitex.Statement.bind_values(statement, [1, "hello"])
  iex(8)> Sqlitex.Statement.fetch_all(statement)
  []
  iex(9)> {:ok, statement} = Sqlitex.Statement.prepare(db, "SELECT * FROM data;")
  iex(10)> Sqlitex.Statement.fetch_all(statement)
  [[id: 1, name: "hello"]]
  iex(11)> Sqlitex.close(db)
  :ok

  ```
  """

  use Pipe

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
    pipe_with &pipe_ok/2,
      do_prepare(db, sql)
      |> get_column_names
      |> get_column_types
  end

  @doc """
  Same as `prepare/2` but raises an error on error.

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
      {:error, _}=error -> error
      :ok -> {:ok, statement}
    end
  end

  @doc """
  Same as `bind_values/2` but raises an error on error.

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
  * `{:error, error}`
  """
  def fetch_all(statement, into \\ []) do
    case :esqlite3.fetchall(statement.statement) do
      {:error, _}=other -> other
      raw_data ->
        Sqlitex.Row.from(
          Tuple.to_list(statement.column_types),
          Tuple.to_list(statement.column_names),
          raw_data, into
        )
    end
  end

  @doc """
  Same as `fetch_all/2` but raises an error on error.

  Returns the results otherwise.
  """
  def fetch_all!(statement, into \\ []) do
    case fetch_all(statement, into) do
      {:ok, results} -> results
      {:error, reason} -> raise Sqlitex.Statement.FetchAllError, reason: reason
    end
  end

  defp do_prepare(db, sql) do
    case :esqlite3.prepare(sql, db) do
      {:ok, statement} ->
        {:ok, %Sqlitex.Statement{database: db, statement: statement}}
      other -> other
    end
  end

  defp get_column_names(%Sqlitex.Statement{statement: sqlite_statement}=statement) do
    case :esqlite3.column_names(sqlite_statement) do
      {:error, _}=other -> other
      names -> {:ok, %Sqlitex.Statement{statement | column_names: names}}
    end
  end

  defp get_column_types(%Sqlitex.Statement{statement: sqlite_statement}=statement) do
    case :esqlite3.column_types(sqlite_statement) do
      {:error, _}=other -> other
      types -> {:ok, %Sqlitex.Statement{statement | column_types: types}}
    end
  end

  defp translate_bindings(params) do
    Enum.map(params, fn
      nil -> :undefined
      true -> 1
      false -> 0
      datetime={{_yr, _mo, _da}, {_hr, _mi, _se, _usecs}} -> datetime_to_string(datetime)
      %Decimal{sign: sign, coef: coef, exp: exp} -> sign * coef * :math.pow(10, exp)
      other -> other
    end)
  end

  defp datetime_to_string({{yr, mo, da}, {hr, mi, se, usecs}}) do
    [zero_pad(yr, 4), "-", zero_pad(mo, 2), "-", zero_pad(da, 2), " ", zero_pad(hr, 2), ":", zero_pad(mi, 2), ":", zero_pad(se, 2), ".", zero_pad(usecs, 6)]
    |> Enum.join
  end

  defp zero_pad(num, len) do
    str = Integer.to_string num
    String.duplicate("0", len - String.length(str)) <> str
  end

  defp pipe_ok(x, f) do
    case x do
      {:ok, val} -> f.(val)
      other -> other
    end
  end
end
