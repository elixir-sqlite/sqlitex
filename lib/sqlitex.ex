defmodule Sqlitex do
  if Version.compare(System.version, "1.3.0") == :lt do
    @type charlist :: char_list
  end

  @type connection :: {:connection, reference(), reference()}
  @type string_or_charlist :: String.t | charlist
  @type sqlite_error :: {:error, {:sqlite_error, charlist}}

  @moduledoc """
  Sqlitex gives you a way to create and query SQLite databases.

  ## Basic Example

  ```
  iex> {:ok, db} = Sqlitex.open(":memory:")
  iex> Sqlitex.exec(db, "CREATE TABLE t (a INTEGER, b INTEGER, c INTEGER)")
  :ok
  iex> Sqlitex.exec(db, "INSERT INTO t VALUES (1, 2, 3)")
  :ok
  iex> Sqlitex.query(db, "SELECT * FROM t")
  {:ok, [[a: 1, b: 2, c: 3]]}
  iex> Sqlitex.query(db, "SELECT * FROM t", into: %{})
  {:ok, [%{a: 1, b: 2, c: 3}]}

  ```

  ## Configuration

  Sqlitex uses the Erlang library [esqlite](https://github.com/mmzeeman/esqlite)
  which accepts a timeout parameter for almost all interactions with the database.
  The default value for this timeout is 5000 ms. Many functions in Sqlitex accept
  a `:db_timeout` option that is passed on to the esqlite calls and also defaults
  to 5000 ms. If required, this default value can be overridden globally with the
  following in your `config.exs`:

  ```
  config :sqlitex, db_timeout: 10_000 # or other positive integer number of ms
  ```

  Another esqlite parameter is :db_chunk_size.
  This is a count of rows to read from native sqlite and send to erlang process in one bulk.
  For example, the table `mytable` has 1000 rows. We make the query to get all rows with `db_chunk_size: 500` parameter:
  ```
  Sqlitex.query(db, "select * from mytable", db_chunk_size: 500)
  ```
  in this case all rows will be passed from native sqlite OS thread to the erlang process in two passes.
  Each pass will contain 500 rows.  
  This parameter decrease overhead of transmitting rows from native OS sqlite thread to the erlang process by
  chunking list of result rows.  
  Please, decrease this value if rows are heavy. Default value is 5000.  
  If you in doubt what to do with this parameter, please, do nothing. Default value is ok.
  ```
  config :sqlitex, db_chunk_size: 500 # if most of the database rows are heavy
  ```
  """

  alias Sqlitex.Config

  @spec close(connection) :: :ok
  @spec close(connection, Keyword.t) :: :ok
  def close(db, opts \\ []) do
    :esqlite3.close(db, Config.db_timeout(opts))
  end

  @spec open(charlist | String.t) :: {:ok, connection} | {:error, {atom, charlist}}
  @spec open(charlist | String.t, Keyword.t) :: {:ok, connection} | {:error, {atom, charlist}}
  def open(path, opts \\ [])
  def open(path, opts) when is_binary(path), do: open(string_to_charlist(path), opts)
  def open(path, opts) do
    :esqlite3.open(path, Config.db_timeout(opts))
  end

  def with_db(path, fun, opts \\ []) do
    {:ok, db} = open(path, opts)
    res = fun.(db)
    close(db, opts)
    res
  end

  @doc """
  Sets a PID to recieve notifications about table updates.

  Messages will come in the shape of:
  `{action, table, rowid}`

  * `action` -> `:insert | :update | :delete`
  * `table` -> charlist of the table name. Example: `'posts'`
  * `rowid` -> internal immutable rowid index of the row.
               This is *NOT* the `id` or `primary key` of the row.
  See the [official docs](https://www.sqlite.org/c3ref/update_hook.html).
  """
  @spec set_update_hook(connection, pid, Keyword.t()) :: :ok | {:error, term()}
  def set_update_hook(db, pid, opts \\ []) do
    :esqlite3.set_update_hook(pid, db, Config.db_timeout(opts))
  end

  @doc """
  Send a raw SQL statement to the database

  This function is intended for running fully-complete SQL statements.
  No query preparation, or binding of values takes place.
  This is generally useful for things like re-playing a SQL export back into the database.
  """
  @spec exec(connection, string_or_charlist) :: :ok | sqlite_error
  @spec exec(connection, string_or_charlist, Keyword.t) :: :ok | sqlite_error
  def exec(db, sql, opts \\ []) do
    :esqlite3.exec(sql, db, Config.db_timeout(opts))
  end

  @doc "A shortcut to `Sqlitex.Query.query/3`"
  @spec query(Sqlitex.connection, String.t | charlist) :: {:ok, [keyword]} | {:error, term()}
  @spec query(Sqlitex.connection, String.t | charlist, [{atom, term}]) :: {:ok, [keyword]} | {:error, term()}
  def query(db, sql, opts \\ []), do: Sqlitex.Query.query(db, sql, opts)

  @doc "A shortcut to `Sqlitex.Query.query!/3`"
  @spec query!(Sqlitex.connection, String.t | charlist) :: [keyword]
  @spec query!(Sqlitex.connection, String.t | charlist, [bind: [], into: Enum.t, db_timeout: integer()]) :: [Enum.t]
  def query!(db, sql, opts \\ []), do: Sqlitex.Query.query!(db, sql, opts)

  @doc "A shortcut to `Sqlitex.Query.query_rows/3`"
  @spec query_rows(Sqlitex.connection, String.t | charlist) :: {:ok, %{}} | Sqlitex.sqlite_error
  @spec query_rows(Sqlitex.connection, String.t | charlist, [bind: [], db_timeout: integer()]) :: {:ok, %{}} | Sqlitex.sqlite_error
  def query_rows(db, sql, opts \\ []), do: Sqlitex.Query.query_rows(db, sql, opts)

  @doc "A shortcut to `Sqlitex.Query.query_rows!/3`"
  @spec query_rows!(Sqlitex.connection, String.t | charlist) :: %{}
  @spec query_rows!(Sqlitex.connection, String.t | charlist, [bind: [], db_timeout: integer()]) :: %{}
  def query_rows!(db, sql, opts \\ []), do: Sqlitex.Query.query_rows!(db, sql, opts)

  @doc """
  Create a new table `name` where `table_opts` is a list of table constraints
  and `cols` is a keyword list of columns. The following table constraints are
  supported: `:temp` and `:primary_key`. Example:

  **[:temp, {:primary_key, [:id]}]**

  Columns can be passed as:
  * name: :type
  * name: {:type, constraints}

  where constraints is a list of column constraints. The following column constraints
  are supported: `:primary_key`, `:not_null` and `:autoincrement`. Example:

  **id: :integer, name: {:text, [:not_null]}**

  """
  def create_table(db, name, table_opts \\ [], cols, call_opts \\ []) do
    stmt = Sqlitex.SqlBuilder.create_table(name, table_opts, cols)
    exec(db, stmt, call_opts)
  end

 if Version.compare(System.version, "1.3.0") == :lt do
   defp string_to_charlist(string), do: String.to_char_list(string)
 else
   defp string_to_charlist(string), do: String.to_charlist(string)
 end
end
