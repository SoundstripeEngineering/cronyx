defmodule Cronyx.Job do
  @moduledoc false
  @type t :: Cronyx.PersistedJob.t() | Cronyx.ManualJob.t()

  def create_job(
        name,
        command,
        schedule,
        description \\ nil,
        allow_concurrency \\ false,
        conditions \\ []
      ) do
    job = %{
      name: name,
      description: description,
      command: command,
      schedule: schedule,
      allow_concurrency: allow_concurrency
    }

    # Cronyx.Db.CronyxJobs.add_job()
    IO.inspect(job, label: "Job to Add")
    IO.inspect(conditions, label: "Conditions to add")
  end

  def create_job(args, conditions \\ []) do
    job = %{
      name: args[:name],
      description: Map.get(args, :description, nil),
      command: args[:command],
      schedule: args[:schedule],
      allow_concurrency: Map.get(args, :allow_concurrency, false)
    }

    IO.inspect(job, label: "Job to Add")
    IO.inspect(conditions, label: "Conditions to add")
  end

  def add_condition(conditions, job_id, condition_job_id, status)
      when is_list(conditions) and is_integer(job_id) and is_integer(condition_job_id) do
    IO.inspect(conditions, label: "ADD CONDITIONS")

    condition_map = %{
      job_id: job_id,
      condition_job_id: condition_job_id,
      status: status
    }

    [condition_map | conditions]
  end

  def add_condition(conditions, job_name, condition_job_name, status) do
    job_name = if is_atom(job_name), do: Atom.to_string(job_name), else: job_name
    job_id = Cronyx.Db.CronyxJobs.get_job_id!(job_name)

    condition_job_name =
      if is_atom(condition_job_name),
        do: Atom.to_string(condition_job_name),
        else: condition_job_name

    condition_job_id = Cronyx.Db.CronyxJobs.get_job_id!(condition_job_name)

    status = if is_atom(status), do: Atom.to_string(status), else: status

    add_condition(conditions, job_id, condition_job_id, status)
  end

  def remove_condition(conditions, job_id, status)
      when is_integer(job_id) and is_binary(status) do
    Enum.reject(conditions, fn
      %{
        job_id: ^job_id,
        status: ^status
      } ->
        true

      _ ->
        false
    end)
  end

  def remove_condition(conditions, job_id, condition_job_id)
      when is_list(conditions) and is_integer(job_id) and is_integer(condition_job_id) do
    Enum.reject(conditions, fn
      %{
        job_id: ^job_id,
        condition_job_id: ^condition_job_id
      } ->
        true

      _ ->
        false
    end)
  end

  def remove_condition(conditions, job_name, condition_job_name, status \\ nil) do
    job_name = if is_atom(job_name), do: Atom.to_string(job_name), else: job_name
    job_id = Cronyx.Db.CronyxJobs.get_job_id!(job_name)

    condition_job_name =
      if is_atom(condition_job_name),
        do: Atom.to_string(condition_job_name),
        else: condition_job_name

    condition_job_id = Cronyx.Db.CronyxJobs.get_job_id!(condition_job_name)

    if status do
      remove_condition(conditions, job_id, condition_job_id, status)
    else
      remove_condition(conditions, job_id, condition_job_id)
    end
  end
end

defmodule Cronyx.PersistedJob do
  @moduledoc """
  `%Cronyx.PersistedJob` defines the job structure for any job retrieved
  from the persisted data store (database).

  ## Arguments:

    * `id` (int) - sequence identifier of the job in the database
    * `name` (str) - job name
    * `description` (str) - job description
    * `schedule` (str) - job schedule in cron notation (e.g. `* * * * *`)
    * `module` (str) - module of job to execute
    * `function` (str) - function to execute
    * `args` (str) - arguments supplied to function
    * `last_run_at` (timestamp) - last run date/time
  """

  defstruct [
    :id,
    :name,
    :description,
    :schedule,
    :module,
    :function,
    :args,
    :last_run_at
  ]
end

defmodule Cronyx.ManualJob do
  @moduledoc """
  `%Cronyx.PersistedJob` defines the job structure for any job retrieved
  from the persisted data store (database).

  ## Arguments:

    * `name` (str) - job name
    * `schedule` (str) - job schedule in cron notation (e.g. `* * * * *`)
    * `func_block` (function) - the function block to execute
    * `last_run_at` (timestamp) - last run date/time
  """

  defstruct [
    :name,
    :schedule,
    :func_block,
    :last_run_at
  ]
end
