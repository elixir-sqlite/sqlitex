defmodule Sqlitex.Server do
  @moduledoc """
  Sqlitex.Server provides a GenServer to wrap a sqlitedb.
  This makes it easy to share a sqlite database between multiple processes without worrying about concurrency issues.
  You can also register the process with a name so you can query by name later.

  ## Unsupervised Example
  ```
  iex> {:ok, pid} = Sqlitex.Server.start_link(":memory:", [name: :example])
  iex> Sqlitex.Server.exec(pid, "CREATE TABLE t (a INTEGER, b INTEGER)")
  :ok
  iex> Sqlitex.Server.exec(pid, "INSERT INTO t (a, b) VALUES (1, 1), (2, 2), (3, 3)")
  :ok
  iex> Sqlitex.Server.query(pid, "SELECT * FROM t WHERE b = 2")
  {:ok, [[a: 2, b: 2]]}
  iex> Sqlitex.Server.query(:example, "SELECT * FROM t ORDER BY a LIMIT 1", into: %{})
  {:ok, [%{a: 1, b: 1}]}
  iex> Sqlitex.Server.query_rows(:example, "SELECT * FROM t ORDER BY a LIMIT 2")
  {:ok, %{rows: [[1, 1], [2, 2]], columns: [:a, :b], types: [:INTEGER, :INTEGER]}}
  iex> Sqlitex.Server.prepare(:example, "SELECT * FROM t")
  {:ok, %{columns: [:a, :b], types: [:INTEGER, :INTEGER]}}
    # Subsequent queries using this exact statement will now operate more efficiently
    # because this statement has been cached.
  iex> Sqlitex.Server.prepare(:example, "INVALID SQL")
  {:error, {:sqlite_error, 'near "INVALID": syntax error'}}
  iex> Sqlitex.Server.stop(:example)
  :ok
  iex> :timer.sleep(10) # wait for the process to exit asynchronously
  iex> Process.alive?(pid)
  false

  ```

  ## Supervised Example
  ```
  import Supervisor.Spec

  children = [
    worker(Sqlitex.Server, ["priv/my_db.sqlite3", [name: :my_db])
  ]

  Supervisor.start_link(children, strategy: :one_for_one)
  ```
  """

  use GenServer

  alias Sqlitex.Statement
  alias Sqlitex.Server.StatementCache, as: Cache

  @doc """
  Starts a SQLite Server (GenServer) instance.

  In addition to the options that are typically provided to `GenServer.start_link/3`,
  you can also specify `stmt_cache_size: (positive_integer)` to override the default
  limit (20) of statements that are cached when calling `prepare/3`.
  """
  def start_link(db_path, opts \\ []) do
    stmt_cache_size = Keyword.get(opts, :stmt_cache_size, 20)
    GenServer.start_link(__MODULE__, {db_path, stmt_cache_size}, opts)
  end

  ## GenServer callbacks

  def init({db_path, stmt_cache_size})
    when is_integer(stmt_cache_size) and stmt_cache_size > 0
  do
    case Sqlitex.open(db_path) do
      {:ok, db} -> {:ok, {db, __MODULE__.StatementCache.new(db, stmt_cache_size)}}
      {:error, reason} -> {:stop, reason}
    end
  end

  def handle_call({:exec, sql}, _from, {db, stmt_cache}) do
    result = Sqlitex.exec(db, sql)
    {:reply, result, {db, stmt_cache}}
  end

  def handle_call({:query, sql, opts}, _from, {db, stmt_cache}) do
    case query_impl(sql, opts, stmt_cache) do
      {:ok, result, new_cache} -> {:reply, {:ok, result}, {db, new_cache}}
      err -> {:reply, err, {db, stmt_cache}}
    end
  end

  def handle_call({:query_rows, sql, opts}, _from, {db, stmt_cache}) do
    case query_rows_impl(sql, opts, stmt_cache) do
      {:ok, result, new_cache} -> {:reply, {:ok, result}, {db, new_cache}}
      err -> {:reply, err, {db, stmt_cache}}
    end
  end

  def handle_call({:prepare, sql}, _from, {db, stmt_cache}) do
    case prepare_impl(sql, stmt_cache) do
      {:ok, result, new_cache} -> {:reply, {:ok, result}, {db, new_cache}}
      err -> {:reply, err, {db, stmt_cache}}
    end
  end

  def handle_call({:create_table, name, table_opts, cols}, _from, {db, stmt_cache}) do
    result = Sqlitex.create_table(db, name, table_opts, cols)
    {:reply, result, {db, stmt_cache}}
  end

  def handle_cast(:stop, {db, stmt_cache}) do
    {:stop, :normal, {db, stmt_cache}}
  end

  def terminate(_reason, {db, _stmt_cache}) do
    Sqlitex.close(db)
    :ok
  end

  ## Public API

  def exec(pid, sql, opts \\ []) do
    GenServer.call(pid, {:exec, sql}, timeout(opts))
  end

  def query(pid, sql, opts \\ []) do
    GenServer.call(pid, {:query, sql, opts}, timeout(opts))
  end

  def query_rows(pid, sql, opts \\ []) do
    GenServer.call(pid, {:query_rows, sql, opts}, timeout(opts))
  end

  @doc """
  Prepares a SQL statement for future use.

  This causes a call to [`sqlite3_prepare_v2`](https://sqlite.org/c3ref/prepare.html)
  to be executed in the Server process. To protect the reference to the corresponding
  [`sqlite3_stmt` struct](https://sqlite.org/c3ref/stmt.html) from misuse in other
  processes, that reference is not passed back. Instead, prepared statements are
  cached in the Server process. If a subsequent call to `query/3` or `query_rows/3`
  is made with a matching SQL statement, the prepared statement is reused.

  Prepared statements are purged from the cache when the cache exceeds a pre-set
  limit (20 statements by default).

  Returns summary information about the prepared statement
  `{:ok, %{columns: [:column1_name, :column2_name,... ], types: [:column1_type, ...]}}`
  on success or `{:error, {:reason_code, 'SQLite message'}}` if the statement
  could not be prepared.
  """
  def prepare(pid, sql, opts \\ []) do
    GenServer.call(pid, {:prepare, sql}, timeout(opts))
  end

  def create_table(pid, name, table_opts \\ [], cols) do
    GenServer.call(pid, {:create_table, name, table_opts, cols})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  ## Helpers

  defp query_impl(sql, opts, stmt_cache) do
    with {%Cache{} = new_cache, stmt} <- Cache.prepare(stmt_cache, sql),
         {:ok, stmt} <- Statement.bind_values(stmt, Keyword.get(opts, :bind, [])),
         {:ok, rows} <- Statement.fetch_all(stmt, Keyword.get(opts, :into, [])),
    do: {:ok, rows, new_cache}
  end

  defp query_rows_impl(sql, opts, stmt_cache) do
    with {%Cache{} = new_cache, stmt} <- Cache.prepare(stmt_cache, sql),
         {:ok, stmt} <- Statement.bind_values(stmt, Keyword.get(opts, :bind, [])),
         {:ok, rows} <- Statement.fetch_all(stmt, :raw_list),
    do: {:ok,
         %{rows: rows, columns: stmt.column_names, types: stmt.column_types},
         new_cache}
  end

  defp prepare_impl(sql, stmt_cache) do
    with {%Cache{} = new_cache, stmt} <- Cache.prepare(stmt_cache, sql),
    do: {:ok, %{columns: stmt.column_names, types: stmt.column_types}, new_cache}
  end

  defp timeout(kwopts), do: Keyword.get(kwopts, :timeout, 5000)
end
