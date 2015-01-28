defmodule Golf.Server do
  use GenServer
  require Logger

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
    GenServer.call(:sup_sqlitex_worker, {:query,sql})
  end
end
