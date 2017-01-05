defmodule Sqlitex do
  @type connection :: {:connection, reference, String.t}
  @type string_or_charlist :: String.t | char_list
  @type sqlite_error :: {:error, {:sqlite_error, char_list}}

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
  """

  @spec close(connection) :: :ok
  def close(db) do
    :esqlite3.close(db)
  end

  @spec open(String.t) :: {:ok, connection}
  @spec open(char_list) :: {:ok, connection} | {:error, {atom, char_list}}
  def open(path) when is_binary(path), do: open(String.to_char_list(path))
  def open(path) do
    :esqlite3.open(path)
  end

  def with_db(path, fun) do
    {:ok, db} = open(path)
    res = fun.(db)
    close(db)
    res
  end

  @spec exec(connection, string_or_charlist) :: :ok | sqlite_error
  def exec(db, sql) do
    :esqlite3.exec(sql, db)
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
  def create_table(db, name, table_opts \\ [], cols) do
    stmt = Sqlitex.SqlBuilder.create_table(name, table_opts, cols)
    exec(db, stmt)
  end
end
