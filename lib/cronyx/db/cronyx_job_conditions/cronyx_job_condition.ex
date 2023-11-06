defmodule Cronyx.Db.CronyxJobConditions.CronyxJobCondition do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  schema "cronyx_job_conditions" do
    field(:condition, :string, default: "success")

    belongs_to(:cronyx_job, Cronyx.Db.CronyxJobs.CronyxJob, foreign_key: :job_id)
    belongs_to(:depends_on, Cronyx.Db.CronyxJobs.CronyxJob, foreign_key: :condition_job_id)

    timestamps()
  end

  def changeset(cronyx_job_conditions, attrs) do
    cronyx_job_conditions
    |> cast(attrs, [
      :id,
      :condition,
      :job_id,
      :condition_job_id
    ])
    |> validate_required([:condition, :job_id, :condition_job_id])
  end
end
