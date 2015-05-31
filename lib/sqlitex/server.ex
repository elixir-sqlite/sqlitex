defmodule Sqlitex.Server do
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
