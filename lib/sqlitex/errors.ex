defmodule Sqlitex.QueryError do
  defexception [:reason]

  def message(error) do
    "Query failed: #{inspect error.reason}"
  end
end

defmodule Sqlitex.Statement.PrepareError do
  defexception [:reason]

  def message(error) do
    "Prepare statement failed: #{inspect error.reason}"
  end
end

defmodule Sqlitex.Statement.BindValuesError do
  defexception [:reason]

  def message(error) do
    "Bind values failed: #{inspect error.reason}"
  end
end

defmodule Sqlitex.Statement.FetchAllError do
  defexception [:reason]

  def message(error) do
    "Fetch all failed: #{inspect error.reason}"
  end
end

defmodule Sqlitex.Statement.ExecError do
  defexception [:reason]

  def message(error) do
    "Exec failed: #{inspect error.reason}"
  end
end
