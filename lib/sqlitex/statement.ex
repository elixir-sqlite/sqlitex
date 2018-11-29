defmodule Sqlitex.Statement do
  alias Sqlitex.Row
  @moduledoc """
  Provides an interface for working with SQLite prepared statements.

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

  ## RETURNING Clause Support

  SQLite does not support the RETURNING extension to INSERT, DELETE, and UPDATE
  commands. (See https://www.postgresql.org/docs/9.6/static/sql-insert.html for
  a description of the Postgres implementation of this clause.)

  Ecto 2.0+ relies on being able to capture this information, so have invented our
  own implementation with the following syntax:

  ```
  ;--RETURNING ON [INSERT | UPDATE | DELETE] <table>,<col>,<col>,...
  ```

  When the `prepare/2` and `prepare!/2` functions are given a query that contains
  the above returning clause, they separate this clause from the end of the query
  and store it separately in the `Statement` struct. Only the portion of the query
  preceding the returning clause is passed to SQLite's prepare function.

  Later, when such a statement struct is passed to `fetch_all/2` or `fetch_all!/2`
  the returning clause is parsed and the query is performed with the following
  additional logic:

  ```
  SAVEPOINT sp_<random>;
  CREATE TEMP TABLE temp.t_<random> (<returning>);
  CREATE TEMP TRIGGER tr_<random> AFTER UPDATE ON main.<table> BEGIN
      INSERT INTO t_<random> SELECT NEW.<returning>;
  END;
  UPDATE ...; -- whatever the original statement was
  DROP TRIGGER tr_<random>;
  SELECT <returning> FROM temp.t_<random>;
  DROP TABLE temp.t_<random>;
  RELEASE sp_<random>;
  ```

  A more detailed description of the motivations for making this change is here:
  https://github.com/jazzyb/sqlite_ecto/wiki/Sqlite.Ecto's-Pseudo-Returning-Clause
  """

  defstruct database: nil,
            statement: nil,
            returning: nil,
            column_names: [],
            column_types: []

  alias Sqlitex.Config

  @doc """
  Prepare a Sqlitex.Statement

  ## Parameters

  * `db` - The database to prepare the statement for.
  * `sql` - The SQL of the statement to prepare.

  Also accepts the following keyword options:

  * `db_timeout` - The time in ms allowed for the statement to run. Defaults to 5000, or the :db_timeout value in Application env.

  ## Returns

  * `{:ok, statement}` on success
  * See `:esqlite3.prepare` for errors.
  """
  def prepare(db, sql, opts \\ []) do
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())

    with {:ok, stmt} <- do_prepare(db, sql, timeout),
         {:ok, stmt} <- get_column_names(stmt, timeout),
         {:ok, stmt} <- get_column_types(stmt, timeout),
         {:ok, stmt} <- extract_returning_clause(stmt, sql),
    do: {:ok, stmt}
  end

  @doc """
  Same as `prepare/3` but raises a Sqlitex.Statement.PrepareError on error.

  Returns a new statement otherwise.
  """
  def prepare!(db, sql, opts \\ []) do
    case prepare(db, sql, opts) do
      {:ok, statement} -> statement
      {:error, reason} -> raise Sqlitex.Statement.PrepareError, reason: reason
    end
  end

  @doc """
  Binds values to a Sqlitex.Statement.

  ## Parameters

  * `statement` - The statement to bind values into.
  * `values` - A list of values to bind into the statement.

  Also accepts the following keyword options:

  * `db_timeout` - The time in ms allowed for the statement to run. Defaults to 5000, or the :db_timeout value in Application env.

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
  def bind_values(statement, values, opts \\ []) do
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())

    case :esqlite3.bind(statement.statement, translate_bindings(values), timeout) do
      {:error, _} = error -> error
      :ok -> {:ok, statement}
    end
  end

  @doc """
  Same as `bind_values/3` but raises a Sqlitex.Statement.BindValuesError on error.

  Returns the statement otherwise.
  """
  def bind_values!(statement, values, opts \\ []) do
    case bind_values(statement, values, opts) do
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
    case raw_fetch_all(statement) do
      {:error, _} = other -> other
      raw_data ->
        {:ok, Row.from(statement.column_types, statement.column_names, raw_data, into)}
    end
  end

  defp raw_fetch_all(%__MODULE__{returning: nil, statement: statement}) do
    :esqlite3.fetchall(statement)
  end
  defp raw_fetch_all(statement) do
    returning_query(statement)
  end

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

  Also accepts the following keyword options:

  * `db_timeout` - The time in ms allowed for the statement to run. Defaults to 5000, or the :db_timeout value in Application env.

  ## Returns

  * `:ok`
  * `{:error, error}`
  """
  def exec(statement, opts \\ []) do
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())

    case :esqlite3.step(statement.statement, timeout) do
      # esqlite3.step returns some odd values, so let's translate them:
      :"$done" -> :ok
      :"$busy" -> {:error, {:busy, "Sqlite database is busy"}}
      other -> other
    end
  end

  @doc """
  Same as `exec/2` but raises a Sqlitex.Statement.ExecError on error.

  Returns :ok otherwise.
  """
  def exec!(statement, opts \\ []) do
    case exec(statement, opts) do
      :ok -> :ok
      {:error, reason} -> raise Sqlitex.Statement.ExecError, reason: reason
    end
  end

  defp do_prepare(db, sql, timeout) do
    case :esqlite3.prepare(sql, db, timeout) do
      {:ok, statement} ->
        {:ok, %Sqlitex.Statement{database: db, statement: statement}}
      other -> other
    end
  end

  defp get_column_names(%Sqlitex.Statement{statement: sqlite_statement} = statement, timeout) do
    names =
      sqlite_statement
      |> :esqlite3.column_names(timeout)
      |> Tuple.to_list
    {:ok, %Sqlitex.Statement{statement | column_names: names}}
  end

  defp get_column_types(%Sqlitex.Statement{statement: sqlite_statement} = statement, timeout) do
    types =
      sqlite_statement
      |> :esqlite3.column_types(timeout)
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

  # --- Returning clause support

  @pseudo_returning_statement ~r(\s*;--RETURNING\s+ON\s+)i

  defp extract_returning_clause(statement, sql) do
    if Regex.match?(@pseudo_returning_statement, sql) do
      [_, returning_clause] = Regex.split(@pseudo_returning_statement, sql, parts: 2)
      case parse_return_contents(returning_clause) do
        {_table, cols, _command, _ref} = info ->
          {:ok, %{statement | returning: info,
                              column_names: Enum.map(cols, &String.to_atom/1),
                              column_types: Enum.map(cols, fn _ -> nil end)}}
        err ->
          err
      end
    else
      {:ok, statement}
    end
  end

  defp parse_return_contents(<<"INSERT ", values::binary>>) do
    [table | cols] = String.split(values, ",")
    {table, cols, "INSERT", "NEW"}
  end

  defp parse_return_contents(<<"UPDATE ", values::binary>>) do
    [table | cols] = String.split(values, ",")
    {table, cols, "UPDATE", "NEW"}
  end

  defp parse_return_contents(<<"DELETE ", values::binary>>) do
    [table | cols] = String.split(values, ",")
    {table, cols, "DELETE", "OLD"}
  end

  defp parse_return_contents(_) do
    {:error, :invalid_returning_clause}
  end

  defp returning_query(%__MODULE__{database: db} = stmt) do
    sp = "sp_#{random_id()}"
    {:ok, _} = db_exec(db, "SAVEPOINT #{sp}")

    case returning_query_in_savepoint(sp, stmt) do
      {:error, _} = error ->
        rollback(db, sp)
        error
      result ->
        {:ok, _} = db_exec(db, "RELEASE #{sp}")
        result
    end
  end

  defp returning_query_in_savepoint(sp, %__MODULE__{database: db,
                                                    statement: statement,
                                                    returning: {table, cols, cmd, ref}})
  do
    temp_table = "t_#{random_id()}"
    temp_fields = Enum.join(cols, ", ")

    trigger_name = "tr_#{random_id()}"
    trigger_fields = Enum.map_join(cols, ", ", &"#{ref}.#{&1}")
    trigger = """
    CREATE TEMP TRIGGER #{trigger_name} AFTER #{cmd} ON main.#{table} BEGIN
      INSERT INTO #{temp_table} SELECT #{trigger_fields};
    END;
    """

    column_names = Enum.join(cols, ", ")

    with {:ok, _} = db_exec(db, "CREATE TEMP TABLE #{temp_table} (#{temp_fields})"),
         {:ok, _} = db_exec(db, trigger),
         result = :esqlite3.fetchall(statement),
         {:ok, rows} = db_exec(db, "SELECT #{column_names} FROM #{temp_table}"),
         {:ok, _} = db_exec(db, "DROP TRIGGER IF EXISTS #{trigger_name}"),
         {:ok, _} = db_exec(db, "DROP TABLE IF EXISTS #{temp_table}")
    do
      if is_list(result), do: rows, else: result
    end
  catch
    e ->
      rollback(db, sp)
      raise e
  end

  defp rollback(db, sp) do
    {:ok, _} = db_exec(db, "ROLLBACK TO SAVEPOINT #{sp}")
    {:ok, _} = db_exec(db, "RELEASE #{sp}")
  end

  @spec db_exec(Sqlitex.connection, iodata()) :: {:ok, [tuple()]}
  defp db_exec(db, sql) do
    case :esqlite3.q(sql, db) do
      {:error, _} = error ->
        error
      result ->
        {:ok, result}
    end
  end

  defp random_id, do: :rand.uniform |> Float.to_string |> String.slice(2..10)
end
