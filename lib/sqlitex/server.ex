defmodule Sqlitex.Server do
  use GenServer

  def start_link(db_path) do
    {:ok, db} = Sqlitex.open(db_path)
    GenServer.start_link(__MODULE__, db, [name: __MODULE__])
  end

  def handle_call({:query, sql}, _from, db) do
    rows = Sqlitex.query(db, sql)
    {:reply, rows, db}
  end

  def handle_call({:create, name, cols}, _from, db) do
    result = Sqlitex.create(db, name, cols)
    {:reply, result, db}
  end

  def handle_call({:exec, sql}, _from, db) do
    result = Sqlitex.exec(db, sql)
    {:reply, result, db}
  end

  ## Public API

  def query(sql) do
    GenServer.call(__MODULE__, {:query, sql})
  end

  def create(name, cols) do
    GenServer.call(__MODULE__, {:create, name, cols})
  end

  def exec(sql) do
    GenServer.call(__MODULE__, {:exec, sql})
  end
end
