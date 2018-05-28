defmodule Sqlitex.Config do
  @moduledoc false

  def db_timeout do
    Application.get_env(:sqlitex, :db_timeout, 5_000)
  end
end
