defmodule Sqlitex do
  if Version.compare(System.version, "1.3.0") == :lt do
    @type charlist :: char_list
  end

  @type connection :: {:connection, reference, binary()}
  @type string_or_charlist :: String.t | charlist
  @type sqlite_error :: {:error, {:sqlite_error, charlist}}

  @moduledoc """
  Sqlitex gives you a way to create and query sqlite databases.

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
  a timeout parameter that is passed on to the esqlite calls and that also defaults
  to 5000 ms. If required, this default value can be overridden globally with the
  following in your `config.exs`:

  ```
  config :sqlitex,
    esqlite3_timeout: 10_000 # or other positive integer number of ms
  ```
  """

  @esqlite3_timeout Application.get_env(:sqlitex, :esqlite3_timeout, 5_000)

  @spec close(connection, integer()) :: :ok
  def close(db, timeout \\ @esqlite3_timeout) do
    :esqlite3.close(db, timeout)
  end

  @spec open(charlist | String.t, integer()) :: {:ok, connection} | {:error, {atom, charlist}}
  def open(path, timeout \\ @esqlite3_timeout)
  def open(path, timeout) when is_binary(path), do: open(string_to_charlist(path), timeout)
  def open(path, timeout) do
    :esqlite3.open(path, timeout)
  end

  def with_db(path, fun, timeout \\ @esqlite3_timeout) do
    {:ok, db} = open(path, timeout)
    res = fun.(db)
    close(db, timeout)
    res
  end

  @spec exec(connection, string_or_charlist, integer()) :: :ok | sqlite_error
  def exec(db, sql, timeout \\ @esqlite3_timeout) do
    :esqlite3.exec(sql, db, timeout)
  end

  def query(db, sql, opts \\ []), do: Sqlitex.Query.query(db, sql, opts)
  def query!(db, sql, opts \\ []), do: Sqlitex.Query.query!(db, sql, opts)

  def query_rows(db, sql, opts \\ []), do: Sqlitex.Query.query_rows(db, sql, opts)
  def query_rows!(db, sql, opts \\ []), do: Sqlitex.Query.query_rows!(db, sql, opts)

  @doc """
  Create a new table `name` where `table_opts` are a list of table constraints
  and `cols` are a keyword list of columns. The following table constraints are
  supported: `:temp` and `:primary_key`. Example:

  **[:temp, {:primary_key, [:id]}]**

  Columns can be passed as:
  * name: :type
  * name: {:type, constraints}

  where constraints is a list of column constraints. The following column constraints
  are supported: `:primary_key`, `:not_null` and `:autoincrement`. Example:

  **id: :integer, name: {:text, [:not_null]}**

  """
  def create_table(db, name, table_opts \\ [], cols, timeout \\ @esqlite3_timeout) do
    stmt = Sqlitex.SqlBuilder.create_table(name, table_opts, cols)
    exec(db, stmt, timeout)
  end

 if Version.compare(System.version, "1.3.0") == :lt do
   defp string_to_charlist(string), do: String.to_char_list(string)
 else
   defp string_to_charlist(string), do: String.to_charlist(string)
 end
end
