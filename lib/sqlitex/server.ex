defmodule Sqlitex.Server do
  use GenServer

  def start_link(db_path) do
    {:ok, db} = Sqlitex.open(db_path)
    GenServer.start_link(__MODULE__, db)
  end

  def handle_call({:exec, sql}, _from, db) do
    result = Sqlitex.exec(db, sql)
    {:reply, result, db}
  end

  def handle_call({:query, sql, params}, _from, db) do
    rows = Sqlitex.query(db, sql, params)
    {:reply, rows, db}
  end

  def handle_call(:stop, _from, db) do
    {:stop, :normal, Sqlitex.close(db), db}
  end

  ## Public API

  def exec(pid, sql) do
    GenServer.call(pid, {:exec, sql})
  end

  def query(pid, sql, params \\ []) do
    GenServer.call(pid, {:query, sql, params})
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end
end
