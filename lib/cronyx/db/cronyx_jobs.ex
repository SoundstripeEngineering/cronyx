defmodule Cronyx.Db.CronyxJobs do
  import Ecto.Query

  alias Cronyx.Repo
  alias Cronyx.Db.CronyxJobs.CronyxJob
  alias Cronyx.Db.CronyxJobConditions.CronyxJobCondition
  alias Cronyx.Cron.Expression, as: CronTab

  @status_always_on_complete "always_on_complete"
  @status_completed "completed"
  @status_runnable ["pending", "succeeded", "failed"]

  defp base_query do
    from(j in CronyxJob)
  end

  def get_job!(id) when is_integer(id) do
    query =
      CronyxJob
      |> where([j], j.id == ^id)

    Repo.repo().one(query)
  end

  def get_job!(name) do
    query =
      CronyxJob
      |> where([j], j.name == ^name)

    Repo.repo().one(query)
  end

  def get_job_id!(name) do
    query =
      CronyxJob
      |> where([j], j.name == ^name)
      |> select([j], j.id)

    case Repo.repo().one(query) do
      nil -> "No job found with name #{name}"
      id -> id
    end
  end

  def list_all_jobs do
    base_query()
    |> Repo.repo().all()
  end

  defp by_status(query, status) do
    from(j in query, where: j.status == ^status)
  end

  def list_jobs(status) do
    base_query()
    |> by_status(status)
    |> Repo.repo().all()
  end

  def add_job(job_details) when is_map(job_details) do
    %CronyxJob{}
    |> CronyxJob.changeset(job_details)
    |> Repo.repo().insert()
    |> case do
      {:ok, job} -> job
      {:error, changeset} -> {:error, changeset}
    end
  end

  def add_job(name, description, command, schedule) do
    add_job(%{
      name: name,
      description: description,
      command: command,
      schedule: schedule
    })
  end

  def update_job_status(id, new_status \\ "running") do
    changeset =
      Repo.repo().get!(CronyxJob, id)
      |> CronyxJob.changeset(%{status: new_status})

    Repo.repo().update(changeset)
  end

  def update_last_run(id) do
    changeset =
      Repo.repo().get!(CronyxJob, id)
      |> CronyxJob.changeset(%{last_run_at: DateTime.utc_now()})

    Repo.repo().update(changeset)
  end

  def update_value(id, column, value) when is_integer(id) do
    case get_job!(id) do
      nil ->
        {:error, "Record not found"}

      cronyx_job ->
        update_value(cronyx_job, column, value)
    end
  end

  def update_value(name, column, value) when is_binary(name) do
    case get_job!(name) do
      nil ->
        {:error, "Record not found"}

      cronyx_job ->
        update_value(cronyx_job, column, value)
    end
  end

  def update_value(job, column, value) do
    changeset =
      job
      |> Ecto.Changeset.change(%{column => value})

    Repo.repo().update(changeset)
    |> case do
      {:ok, job} -> job
      {:error, changeset} -> {:error, changeset}
    end
  end

  def list_valid_jobs() do
    # Define union_query only once
    union_query =
      CronyxJob
      |> where(
        [j],
        (j.status == "running" and j.allow_concurrency == true) or
          j.status in ^@status_runnable
      )

    # Combine jobs without conditions
    jobs_without_conditions =
      from(j in subquery(union_query),
        left_join: t in CronyxJobCondition,
        on: t.job_id == j.id,
        where: is_nil(t.id)
      )

    # Count valid condition for each job
    valid_condition_counts =
      from(j in subquery(union_query),
        join: t in CronyxJobCondition,
        on: t.job_id == j.id,
        join: dj in CronyxJob,
        on: dj.id == t.condition_job_id,
        where:
          (t.condition == @status_always_on_complete and dj.status in ^@status_runnable) or
            ((t.condition == dj.status or
                (t.condition == @status_completed and dj.status in ^@status_runnable)) and
               dj.last_run_at > j.last_run_at),
        group_by: j.id,
        select: %{id: j.id, count: count(t.id)}
      )

    # Count total conditions for each job
    total_condition_counts =
      from(j in subquery(union_query),
        join: t in CronyxJobCondition,
        on: t.job_id == j.id,
        group_by: j.id,
        select: %{id: j.id, count: count(t.id)}
      )

    # Join on job ID and filter where counts match
    jobs_with_all_valid_conditions =
      from(j in subquery(union_query),
        join: v in subquery(valid_condition_counts),
        on: v.id == j.id,
        join: t in subquery(total_condition_counts),
        on: t.id == j.id,
        where: v.count == t.count
      )

    # Union jobs without conditions and jobs with all valid conditions
    combined_jobs =
      union_all(jobs_without_conditions, ^jobs_with_all_valid_conditions)

    # Get distinct jobs
    distinct_jobs = from(j in combined_jobs, distinct: j.id)

    # Query and Filter by Job Schedule
    Repo.repo().all(distinct_jobs)
    |> Enum.filter(fn record ->
      CronTab.now?(CronTab.parse!(record.schedule))
    end)
  end
end
