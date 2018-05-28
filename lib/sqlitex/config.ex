defmodule Sqlitex.Config do
  @moduledoc false

  def esqlite3_timeout do
    Application.get_env(:sqlitex, :esqlite3_timeout, default_esqlite3_timeout())
  end

  def default_esqlite3_timeout, do: 5_000
end
