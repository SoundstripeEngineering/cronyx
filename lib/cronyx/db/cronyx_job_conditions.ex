defmodule Cronyx.Db.CronyxJobConditions do
  import Ecto.Query

  alias Cronyx.Repo
  alias Cronyx.Db.CronyxJobConditions.CronyxJobCondition

  defp base_query do
    from(c in CronyxJobCondition)
  end

  defp by_job_id(query, job_id) do
    from(c in query, where: c.job_id == ^job_id)
  end

  defp by_condition_job_id(query, condition_job_id) do
    from(c in query, where: c.condition_job_id == ^condition_job_id)
  end

  defp by_condition(query, condition) do
    from(c in query, where: c.condition == ^condition)
  end

  def list_all_job_conditions, do: CronyxJobCondition |> Repo.repo().all()

  def list_by_job_id(job_id) do
    base_query()
    |> by_job_id(job_id)
    |> Repo.repo().all()
  end

  def list_by_condition_job_id(condition_job_id) do
    base_query()
    |> by_condition_job_id(condition_job_id)
    |> Repo.repo().all()
  end

  def list_by_condition(condition) do
    base_query()
    |> by_condition(condition)
    |> Repo.repo().all()
  end

  def add_job_condition(condition_details) when is_map(condition_details) do
    %CronyxJobCondition{}
    |> CronyxJobCondition.changeset(condition_details)
    |> Repo.repo().insert()
    |> case do
      {:ok, condition} -> condition
      {:error, changeset} -> {:error, changeset}
    end
  end

  def add_job_condition(job_id, condition_job_id, condition) do
    add_job_condition(%{
      job_id: job_id,
      condition_job_id: condition_job_id,
      condition: condition
    })
  end

  def update_job_condition(job, job_id, condition_job_id, condition) do
    changeset =
      job
      |> Ecto.Changeset.change(%{
        job_id: job_id,
        condition_job_id: condition_job_id,
        condition: condition
      })

    Repo.repo().update(changeset)
  end

  def get_job_condition(id) do
    query =
      CronyxJobCondition
      |> where([c], c.id == ^id)

    Repo.repo().one(query)
  end

  def get_job_condition(job_id, condition_job_id) do
    query =
      CronyxJobCondition
      |> where([c], c.job_id == ^job_id and c.condition_job_id == ^condition_job_id)

    Repo.repo().one(query)
  end
end
