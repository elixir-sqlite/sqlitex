defmodule SqlBuilderTest do
  alias Sqlitex.SqlBuilder, as: Sql
  use ExUnit.Case

  test "basic table creation" do
    sql = Sql.create_table(:users, [], id: :integer, name: :text)
    assert sql == "CREATE  TABLE \"users\" (\"id\" integer, \"name\" text )"
  end

  test "creating a temporary table" do
    sql = Sql.create_table(:users, [:temp], id: :integer, name: :text)
    assert sql == "CREATE TEMP TABLE \"users\" (\"id\" integer, \"name\" text )"
  end

  test "creating a table with a primary key" do
    sql = Sql.create_table(:dinosaurs, [primary_key: :id], id: :integer, name: :text)
    assert sql == "CREATE  TABLE \"dinosaurs\" (\"id\" integer, \"name\" text ,PRIMARY KEY (\"id\"))"
  end

  test "creating a table with multiple primary keys" do
    sql = Sql.create_table(:dinosaurs, [primary_key: [:id, :type]], id: :integer, type: :integer, name: :text)
    assert sql == "CREATE  TABLE \"dinosaurs\" (\"id\" integer, \"type\" integer, \"name\" text ,PRIMARY KEY (\"id\",\"type\"))"
  end

  test "creating a table with NOT NULL columns" do
    sql = Sql.create_table(:users, [], id: {:integer, [:not_null]}, name: :text)
    assert sql == "CREATE  TABLE \"users\" (\"id\" integer NOT NULL, \"name\" text )"
  end

  test "creating a table with PRIMARY KEY columns" do
    sql = Sql.create_table(:users, [], id: {:integer, [:primary_key]}, name: :text)
    assert sql == "CREATE  TABLE \"users\" (\"id\" integer PRIMARY KEY, \"name\" text )"
  end

  test "creating a table with AUTOINCREMENT columns" do
    sql = Sql.create_table(:users, [], id: {:integer, [:autoincrement]}, name: :text)
    assert sql == "CREATE  TABLE \"users\" (\"id\" integer AUTOINCREMENT, \"name\" text )"
  end
end
