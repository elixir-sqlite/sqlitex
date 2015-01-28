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

  ## Public API

  def query(sql) do
    GenServer.call(__MODULE__, {:query, sql})
  end
end
