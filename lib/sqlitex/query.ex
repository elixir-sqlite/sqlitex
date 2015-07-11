defmodule Sqlitex.Query do
  use Pipe

  alias Sqlitex.Statement

  def query(db, sql, opts \\ []) do
    pipe_with &pipe_ok/2,
      Statement.prepare(db, sql)
      |> Statement.bind_values(Dict.get(opts, :bind, []))
      |> Statement.fetch_all(Dict.get(opts, :into, []))
  end

  def query!(db, sql, opts \\ []) do
    {:ok, results} = query(db, sql, opts)
    results
  end

  defp pipe_ok(x, f) do
    case x do
      {:ok, val} -> f.(val)
      other -> other
    end
  end
end
