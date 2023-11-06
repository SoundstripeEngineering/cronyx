defmodule Cronyx.Db.CronyxJobs.CronyxJob do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "cronyx_jobs" do
    field(:name, :string)
    field(:description, :string)
    field(:command, :string)
    field(:schedule, :string, default: "* * * * *")
    field(:allow_concurrency, :boolean, default: false)
    field(:status, :string, default: "disabled")
    field(:last_run_at, :naive_datetime)

    has_many(:cronyx_job_runs, Cronyx.Db.CronyxJobRuns.CronyxJobRun, foreign_key: :job_id)

    has_many(:conditions_originating, Cronyx.Db.CronyxJobConditions.CronyxJobCondition,
      foreign_key: :job_id
    )

    has_many(:conditions_dependent, Cronyx.Db.CronyxJobConditions.CronyxJobCondition,
      foreign_key: :condition_job_id
    )

    timestamps()
  end

  def changeset(cronyx_jobs, attrs) do
    cronyx_jobs
    |> cast(attrs, [
      :name,
      :description,
      :command,
      :schedule,
      :allow_concurrency,
      :status,
      :last_run_at
    ])
    |> validate_required([:name, :command])
    |> validate_inclusion(:status, [
      "succeeded",
      "failed",
      "running",
      "starting",
      "canceled",
      "terminated",
      "disabled",
      "exclude",
      "ignore",
      "pending"
    ])
    |> validate_length(:name, min: 1, max: 255)
    |> validate_length(:command, min: 1, max: 2048)
  end
end
