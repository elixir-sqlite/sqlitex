defmodule Sqlitex.ServerTest do
  use ExUnit.Case
  doctest Sqlitex.Server

  test "with_transaction commit" do
    alias Sqlitex.Server

    {:ok, server} = Server.start_link(':memory:')
    :ok = Server.exec(server, "create table foo(id integer)")

    Server.with_transaction(server, fn db ->
      :ok = Server.exec(db, "insert into foo (id) values (42)")
    end)

    assert Server.query(server, "select * from foo") == {:ok, [[{:id, 42}]]}
  end

  test "with_transaction rollback" do
    alias Sqlitex.Server

    {:ok, server} = Server.start_link(':memory:')
    :ok = Server.exec(server, "create table foo(id integer)")

    try do
      Server.with_transaction(server, fn db ->
        :ok = Server.exec(db, "insert into foo (id) values (42)")
        raise "Error to roll back transaction"
      end)
    rescue
      _ -> nil
    end

    assert Server.query(server, "select * from foo") == {:ok, []}
  end
end
