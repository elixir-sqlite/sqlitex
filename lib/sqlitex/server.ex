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
  iex> Sqlitex.Server.stop(:example)
  :ok
  iex> Process.sleep(10) # wait for the process to exit asynchronously
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

  def start_link(db_path, opts \\ []) do
    GenServer.start_link(__MODULE__, db_path, opts)
  end

  ## GenServer callbacks

  def init(db_path) do
    case Sqlitex.open(db_path) do
      {:ok, db} -> {:ok, db}
      {:error, reason} -> {:stop, reason}
    end
  end

  def handle_call({:exec, sql}, _from, db) do
    result = Sqlitex.exec(db, sql)
    {:reply, result, db}
  end

  def handle_call({:query, sql, opts}, _from, db) do
    rows = Sqlitex.query(db, sql, opts)
    {:reply, rows, db}
  end

  def handle_call({:create_table, name, table_opts, cols}, _from, db) do
    result = Sqlitex.create_table(db, name, table_opts, cols)
    {:reply, result, db}
  end

  def handle_cast(:stop, db) do
    {:stop, :normal, db}
  end

  def terminate(_reason, db) do
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

  def create_table(pid, name, table_opts \\ [], cols) do
    GenServer.call(pid, {:create_table, name, table_opts, cols})
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  ## Helpers

  defp timeout(kwopts), do: Keyword.get(kwopts, :timeout, 5000)
end
