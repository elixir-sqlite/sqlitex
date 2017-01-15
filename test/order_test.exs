defmodule Sqlitex.OrderTest do
  use ExUnit.Case
  use ExCheck

  property :ordering_query_results do
    for_all {x, y} in {int(), int()} do
      {:ok, db} = Sqlitex.open(":memory:")
      :ok = Sqlitex.exec(db, "CREATE TABLE t (a INTEGER)")
      :ok = Sqlitex.exec(db, "INSERT INTO t (a) VALUES #{(x..y) |> Enum.map(&( "(#{&1})" )) |> Enum.join(",")}")
      Enum.sort(Enum.to_list(x..y)) == Enum.map(Sqlitex.query!(db, "SELECT a FROM t ORDER BY a"), &(&1[:a]))
    end
  end
end
