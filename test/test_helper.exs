ExCheck.start
ExUnit.start()

# Include TestDatabase:
[File.cwd!, "test", "test_database.exs"] |> Path.join |> Code.require_file
