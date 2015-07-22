defmodule Sqlitex.Query do
  use Pipe

  alias Sqlitex.Statement

  @doc """
  Runs a query and returns the results.

  ## Parameters

  * `db` - A sqlite database.
  * `sql` - The query to run as a string.
  * `opts` - Options to pass into the query.  See below for details.

  ## Options

  * `bind` - If your query has parameters in it, you should provide the options
    to bind as a list.
  * `into` - The collection to put results into.  This defaults to a list.

  ## Returns
  * [results...] on success
  * {:error, _} on failure.
  """

  def query(db, sql, opts \\ []) do
    pipe_with &pipe_ok/2,
      Statement.prepare(db, sql)
      |> Statement.bind_values(Dict.get(opts, :bind, []))
      |> Statement.fetch_all(Dict.get(opts, :into, []))
  end

  @doc """
  Same as `query/3` but raises a Sqlitex.QueryError on error.

  Returns the results otherwise.
  """
  def query!(db, sql, opts \\ []) do
    case query(db, sql, opts) do
      {:error, reason} -> raise Sqlitex.QueryError, reason: reason
      results -> results
    end
  end

  defp pipe_ok(x, f) do
    case x do
      {:ok, val} -> f.(val)
      other -> other
    end
  end
end
