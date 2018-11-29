defmodule Sqlitex.Query do
  alias Sqlitex.Statement

  @doc """
  Runs a query and returns the results.

  ## Parameters

  * `db` - A SQLite database.
  * `sql` - The query to run as a string.
  * `opts` - Options to pass into the query.  See below for details.

  ## Options

  * `bind` - If your query has parameters in it, you should provide the options
    to bind as a list.
  * `into` - The collection to put results into.  This defaults to a list.
  * `db_timeout` - The timeout (in ms) to apply to each of the underlying SQLite operations. Defaults
    to `Application.get_env(:sqlitex, :db_timeout)` or `5000` ms if not configured.

  ## Returns
  * [results...] on success
  * {:error, _} on failure.
  """

  if Version.compare(System.version, "1.3.0") == :lt do
    @type charlist :: char_list
  end

  @spec query(Sqlitex.connection, String.t | charlist) :: {:ok, [[]]} | {:error, term()}
  @spec query(Sqlitex.connection, String.t | charlist, [{atom, term}]) :: {:ok, [[]]} | {:error, term()}
  def query(db, sql, opts \\ []) do
    with {:ok, stmt} <- Statement.prepare(db, sql, opts),
         {:ok, stmt} <- Statement.bind_values(stmt, Keyword.get(opts, :bind, []), opts),
         {:ok, res} <- Statement.fetch_all(stmt, Keyword.get(opts, :into, [])),
    do: {:ok, res}
  end

  @doc """
  Same as `query/3` but raises a Sqlitex.QueryError on error.

  Returns the results otherwise.
  """
  @spec query!(Sqlitex.connection, String.t | charlist) :: [[]]
  @spec query!(Sqlitex.connection, String.t | charlist, [bind: [], into: Enum.t, db_timeout: integer()]) :: [Enum.t]
  def query!(db, sql, opts \\ []) do
    case query(db, sql, opts) do
      {:error, reason} -> raise Sqlitex.QueryError, reason: reason
      {:ok, results} -> results
    end
  end

  @doc """
  Runs a query and returns the results as a list of rows each represented as
  a list of column values.

  ## Parameters

  * `db` - A SQLite database.
  * `sql` - The query to run as a string.
  * `opts` - Options to pass into the query.  See below for details.

  ## Options

  * `bind` - If your query has parameters in it, you should provide the options
    to bind as a list.
  * `db_timeout` - The timeout (in ms) to apply to each of the underlying SQLite operations. Defaults
    to `Application.get_env(:sqlitex, :db_timeout)` or `5000` ms if not configured.

  ## Returns
  * {:ok, %{rows: [[1, 2], [2, 3]], columns: [:a, :b], types: [:INTEGER, :INTEGER]}} on success
  * {:error, _} on failure.
  """

  @spec query_rows(Sqlitex.connection, String.t | charlist) :: {:ok, %{}} | Sqlitex.sqlite_error
  @spec query_rows(Sqlitex.connection, String.t | charlist, [bind: [], db_timeout: integer()]) :: {:ok, %{}} | Sqlitex.sqlite_error
  def query_rows(db, sql, opts \\ []) do
    with {:ok, stmt} <- Statement.prepare(db, sql, opts),
         {:ok, stmt} <- Statement.bind_values(stmt, Keyword.get(opts, :bind, []), opts),
         {:ok, rows} <- Statement.fetch_all(stmt, :raw_list),
    do: {:ok, %{rows: rows, columns: stmt.column_names, types: stmt.column_types}}
  end

  @doc """
  Same as `query_rows/3` but raises a Sqlitex.QueryError on error.

  Returns the results otherwise.
  """
  @spec query_rows!(Sqlitex.connection, String.t | charlist) :: %{}
  @spec query_rows!(Sqlitex.connection, String.t | charlist, [bind: [], db_timeout: integer()]) :: %{}
  def query_rows!(db, sql, opts \\ []) do
    case query_rows(db, sql, opts) do
      {:error, reason} -> raise Sqlitex.QueryError, reason: reason
      {:ok, results} -> results
    end
  end
end
