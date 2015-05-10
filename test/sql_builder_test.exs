defmodule SqlBuilderTest do
  use ExUnit.Case

  test "create table sql creation" do
    alias Sqlitex.SqlBuilder, as: Sql

    sql = Sql.create_table(:users, [], id: :integer, name: :text)

    assert sql == "CREATE  TABLE  users ( id integer, name text )"

    sql = Sql.create_table(:users, [:temp], id: :integer, name: :text)

    assert sql == "CREATE TEMP TABLE  users ( id integer, name text )"

    sql = Sql.create_table(:users, [], id: {:integer, [:not_null, :primary_key]}, name: :text)

    assert sql == "CREATE  TABLE  users ( id integer PRIMARY KEY NOT NULL , name text )"
  end
end
