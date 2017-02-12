defmodule Sqlitex.Server.StatementCache do
  @moduledoc """
  Implements a least-recently used (LRU) cache for prepared SQLite statements.

  Caches a fixed number of prepared statements and purges the statements which
  were least-recently used when that limit is exceeded.
  """

  defstruct db: false, size: 0, limit: 1, cached_stmts: %{}, lru: []

  @doc """
  Creates a new prepared statement cache.
  """
  def new({:connection, _, _} = db, limit) when is_integer(limit) and limit > 0 do
    %__MODULE__{db: db, limit: limit}
  end

  @doc """
  Given a statement cache and an SQL statement (string), returns a tuple containing
  the updated statement cache and a prepared SQL statement.

  If possible, reuses an existing prepared statement; if not, prepares the statement
  and adds it to the cache, possibly removing the least-recently used prepared
  statement if the designated cache size limit would be exceeded.

  Will return `{:error, reason}` if SQLite is unable to prepare the statement.
  """
  def prepare(%__MODULE__{cached_stmts: cached_stmts} = cache, sql)
    when is_binary(sql) and byte_size(sql) > 0
  do
    case Map.fetch(cached_stmts, sql) do
      {:ok, stmt} -> {update_cache_for_read(cache, sql), stmt}
      :error -> prepare_new_statement(cache, sql)
    end
  end

  defp prepare_new_statement(%__MODULE__{db: db} = cache, sql) do
    case Sqlitex.Statement.prepare(db, sql) do
      {:ok, prepared} ->
        cache = cache
          |> store_new_stmt(sql, prepared)
          |> purge_cache_if_full
          |> update_cache_for_read(sql)

        {cache, prepared}
      error -> error
    end
  end

  defp store_new_stmt(%__MODULE__{size: size, cached_stmts: cached_stmts} = cache,
                      sql, prepared)
  do
    %{cache | size: size + 1, cached_stmts: Map.put(cached_stmts, sql, prepared)}
  end

  defp purge_cache_if_full(%__MODULE__{size: size,
                                       limit: limit,
                                       cached_stmts: cached_stmts,
                                       lru: [purge_victim | lru]} = cache)
    when size > limit
  do
    %{cache | size: size - 1,
              cached_stmts: Map.drop(cached_stmts, [purge_victim]),
              lru: lru}
  end
  defp purge_cache_if_full(cache), do: cache

  defp update_cache_for_read(%__MODULE__{lru: lru} = cache, sql) do
    lru = lru
      |> Enum.reject(&(&1 == sql))
      |> Kernel.++([sql])

    %{cache | lru: lru}
  end
end
