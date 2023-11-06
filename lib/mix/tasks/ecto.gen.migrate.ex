defmodule Mix.Tasks.Ecto.Gen.Migrate do
  @moduledoc """
  Migraions create and modify the database tables needed to function.

  ## Usage

  To use migrations in your application you'll need to generate an `Ecto.Migration`

  ```elixir
  mix ecto.gen.migration
  ```

  This will copy all versioned migrations for your database. Run the migration
  to create the table.

  ```elixir
  mix ecto.migrate
  ```

  Migrations between versions of the library are idempotent. As new versions are
  released it may be necessary to run additional migrations for changes made
  to the underlying structure.

  Run the same steps:
  ```elixir
  mix ecto.gen.migration
  mix ecto.migrate
  ```
  """
  use Mix.Task

  @target_migration_name "cronyx_migration.exs"

  @doc false
  def run(args) when is_list(args) and args == [], do: transfer_migrations()

  def run(args) do
    [opt | [provided_repo | _]] = args
    if opt != "-r" || !is_binary(provided_repo), do: raise("Invalid Arguments")

    transfer_migrations(Macro.underscore(provided_repo))
  end

  @doc false
  def transfer_migrations(_app_migration_repo \\ "repo") do
    available_migrations = list_migrations(library_migration_path())
    applied_migrations = list_migrations(app_migration_path()) |> extract_applied_versions()

    migrations_to_copy = available_migrations -- applied_migrations

    for migration <- migrations_to_copy do
      source_file = Path.join(library_migration_path(), migration)
      destination_version = extract_version_from_filename(migration)

      destination_file =
        Path.join(
          app_migration_path(),
          "#{timestamp_string()}_#{destination_version}_#{@target_migration_name}"
        )

      File.cp!(source_file, destination_file)
    end

    Mix.shell().info("Migration transferred")
  end

  defp list_migrations(migrations_dir) do
    with {:ok, files} <- File.ls(migrations_dir) do
      files
    else
      {:error, _} -> []
    end
  end

  defp extract_applied_versions(filenames) do
    for filename <- filenames,
        [_, version] <- Regex.scan(~r/^\d+_([vV]\d+)_.*\.exs$/, filename),
        do: "#{version}.exs"
  end

  defp extract_version_from_filename(filename) do
    [version | _rest] = String.splitter(filename, ".", parts: 3) |> Enum.to_list()
    version
  end

  defp timestamp_string do
    {{year, month, day}, {hour, minute, second}} = :calendar.local_time()

    String.pad_leading(Integer.to_string(year), 4, "0") <>
      Enum.map_join([month, day, hour, minute, second], fn x ->
        String.pad_leading(Integer.to_string(x), 2, "0")
      end)
  end

  defp library_migration_path do
    library_priv_dir = :code.priv_dir(:cronyx)
    Path.join([library_priv_dir, "repo", "migration_versions"])
  end

  defp app_migration_path do
    "priv/repo/migrations"
  end
end
