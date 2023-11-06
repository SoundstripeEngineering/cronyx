defmodule Cronyx.Db.CronyxJobRuns.CronyxJobRun do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "cronyx_job_runs" do
    field(:job_name, :string)
    field(:status, :string)
    field(:result_log, :string)

    belongs_to(:cronyx_job, Cronyx.Db.CronyxJobs.CronyxJob, foreign_key: :job_id)

    timestamps()
  end

  def changeset(cronyx_job_runs, attrs) do
    cronyx_job_runs
    |> cast(attrs, [
      :id,
      :job_id,
      :job_name,
      :status,
      :result_log
    ])
    |> validate_required([:status])
    |> validate_inclusion(:status, [
      "succeeded",
      "failed",
      "running",
      "starting",
      "canceled",
      "terminated",
      "disabled",
      "exclude",
      "ignore"
    ])
  end
end
