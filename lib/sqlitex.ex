defmodule Sqlitex do
  if Version.compare(System.version, "1.3.0") == :lt do
    @type charlist :: char_list
  end

  @type connection :: {:connection, reference, binary()}
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
  """

  alias Sqlitex.Config

  @spec close(connection) :: :ok
  @spec close(connection, Keyword.t) :: :ok
  def close(db, opts \\ []) do
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())
    :esqlite3.close(db, timeout)
  end

  @spec open(charlist | String.t) :: {:ok, connection} | {:error, {atom, charlist}}
  @spec open(charlist | String.t, Keyword.t) :: {:ok, connection} | {:error, {atom, charlist}}
  def open(path, opts \\ [])
  def open(path, opts) when is_binary(path), do: open(string_to_charlist(path), opts)
  def open(path, opts) do
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())
    :esqlite3.open(path, timeout)
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
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())
    :esqlite3.set_update_hook(pid, db, timeout)
  end

  @spec exec(connection, string_or_charlist) :: :ok | sqlite_error
  @spec exec(connection, string_or_charlist, Keyword.t) :: :ok | sqlite_error
  def exec(db, sql, opts \\ []) do
    timeout = Keyword.get(opts, :db_timeout, Config.db_timeout())
    :esqlite3.exec(sql, db, timeout)
  end

  def query(db, sql, opts \\ []), do: Sqlitex.Query.query(db, sql, opts)
  def query!(db, sql, opts \\ []), do: Sqlitex.Query.query!(db, sql, opts)

  def query_rows(db, sql, opts \\ []), do: Sqlitex.Query.query_rows(db, sql, opts)
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
