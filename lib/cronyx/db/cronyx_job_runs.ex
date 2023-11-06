defmodule Cronyx.Db.CronyxJobRuns do
  import Ecto.Query

  alias Cronyx.Repo
  alias Cronyx.Db.CronyxJobRuns.CronyxJobRun

  defp base_query do
    from(r in CronyxJobRun)
  end

  def list_all_job_runs do
    base_query()
    |> Repo.repo().all()
  end

  defp by_job_id(query, job_id) do
    from(r in query, where: r.job_id == ^job_id)
  end

  defp by_job_name(query, job_name) do
    from(r in query, where: r.job_name == ^job_name)
  end

  defp by_status(query, status) do
    from(r in query, where: r.status == ^status)
  end

  def list_by_job_id(job_id) do
    base_query()
    |> by_job_id(job_id)
    |> Repo.repo().all()
  end

  def list_by_job_name(job_name) do
    base_query()
    |> by_job_name(job_name)
    |> Repo.repo().all()
  end

  def list_by_status(status) do
    base_query()
    |> by_status(status)
    |> Repo.repo().all()
  end

  defp by_date_range(query, start_date, end_date) do
    from(r in query,
      where: r.inserted_at >= ^start_date and r.inserted_at <= ^end_date
    )
  end

  def list_by_date_range(start_date, end_date) do
    base_query()
    |> by_date_range(start_date, end_date)
    |> Repo.repo().all()
  end

  defp paginate(query, page_number, page_size) do
    offset_value = (page_number - 1) * page_size

    from(r in query,
      limit: ^page_size,
      offset: ^offset_value
    )
  end

  def list_paginated(page_number, page_size \\ 10) do
    base_query()
    |> paginate(page_number, page_size)
    |> Repo.repo().all()
  end

  def list_by_date_range_paginated(start_date, end_date, page_number, page_size \\ 10) do
    base_query()
    |> by_date_range(start_date, end_date)
    |> paginate(page_number, page_size)
    |> Repo.repo().all()
  end

  def add_job_run(%{id: job_id, name: job_name} = _job, status, log) do
    do_add_job_run(%{job_id: job_id, job_name: job_name, status: status, result_log: log})
  end

  def add_job_run(job_name, status, log) when is_binary(job_name) do
    do_add_job_run(%{job_name: job_name, status: status, result_log: log})
  end

  defp do_add_job_run(run_attrs) do
    {:ok, new_record} =
      %CronyxJobRun{}
      |> CronyxJobRun.changeset(run_attrs)
      |> Repo.repo().insert()

    new_record.id
  end

  def update_job_run(id, status, log) do
    run = Repo.repo().get!(CronyxJobRun, id)
    changeset = CronyxJobRun.changeset(run, %{status: status, log: log})

    Repo.repo().update(changeset)
  end
end
