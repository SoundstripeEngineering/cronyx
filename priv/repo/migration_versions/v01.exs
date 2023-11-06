defmodule Cronyx.Repo.Migrations.AddCronyxJobs do
  use Ecto.Migration

  def change do
    unless Cronyx.Repo.table_exists?(:cronyx_jobs) do
      create table(:cronyx_jobs) do
        add :name, :string, null: false
        add :description, :string
        add :command, :string, null: false
        add :schedule, :string, default: "* * * * *", null: false
        add :allow_concurrency, :boolean, default: false
        add :status, :string, default: "disabled"
        add :last_run_at, :naive_datetime

        timestamps()
      end

      create index(:cronyx_jobs, [:name])
      create index(:cronyx_jobs, [:status])
      create index(:cronyx_jobs, [:last_run_at])

      create unique_index(:cronyx_jobs, [:name])
    end

    unless Cronyx.Repo.table_exists?(:cronyx_job_runs) do
      create table(:cronyx_job_runs) do
        add :job_id, references(:cronyx_jobs, on_delete: :delete_all)
        add :job_name, :string
        add :status, :string, null: false
        add :result_log, :string

        timestamps()
      end

      create index(:cronyx_job_runs, [:job_id])
      create index(:cronyx_job_runs, [:status])
    end

    unless Cronyx.Repo.table_exists?(:cronyx_job_conditions) do
      create table(:cronyx_job_conditions) do
        add :job_id, references(:cronyx_jobs, on_delete: :delete_all), null: false
        add :condition_job_id, references(:cronyx_jobs, on_delete: :delete_all), null: false
        add :condition, :string, default: "success", null: false

        timestamps()
      end

      create index(:cronyx_job_conditions, [:job_id])
      create index(:cronyx_job_conditions, [:condition_job_id])

      create unique_index(:cronyx_job_conditions, [:job_id, :condition_job_id])
    end
  end
end
