defmodule Cronyx.Worker do
  alias Cronyx.Db.CronyxJobs
  alias Cronyx.Db.CronyxJobRuns

  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def execute_job(_pid, job) do
    case job.__struct__ do
      Cronyx.PersistedJob ->
        execute(job)

      Cronyx.ManualJob ->
        # Execute stored code block
        execute(job)

      _ ->
        IO.puts("Unknown job type...")
    end
  end

  defp execute(job) when is_struct(job) do
    {log_result, handler} =
      case job do
        %Cronyx.ManualJob{} ->
          {log_execution(job.func_block), &handle_anonymous_result/3}

        %Cronyx.PersistedJob{} ->
          CronyxJobs.update_job_status(job.id)
          {log_execution(job.module, job.function, job.args), &handle_execution_result/3}
      end

    case log_result do
      {:ok, job_output} ->
        handler.(job, "succeeded", job_output)

      {:error, error_message} ->
        handler.(job, "failed", error_message)
    end
  end

  defp log_execution(func_block) when is_function(func_block, 0) do
    do_log_execution(fn -> func_block.() end)
  end

  defp log_execution(module, function, arguments) when is_atom(module) and is_atom(function) do
    do_log_execution(fn -> apply(module, function, arguments) end)
  end

  defp do_log_execution(execution_func) do
    original_group_leader = Process.group_leader()

    {:ok, capture_device} = StringIO.open("")
    Process.group_leader(self(), capture_device)

    result =
      try do
        execution_func.()
        :ok
      catch
        :error, :undef ->
          {:error, "Exception! An exception occurred while executing the code block"}

        :throw, value ->
          {:error, "Exception! #{to_string(value)}"}

        :error, %module{} = exception ->
          exception_type = module |> inspect |> String.split(".") |> List.last()
          exception_message = Exception.message(exception)

          {:error, "Exception! [#{exception_type}] #{exception_message}"}
      end

    Process.group_leader(self(), original_group_leader)

    {_, captured_output} = StringIO.contents(capture_device)

    case result do
      :ok ->
        {:ok, captured_output}

      {:error, message} when is_binary(message) ->
        error_message = build_error_message(captured_output, message)
        {:error, error_message}
    end
  end

  defp build_error_message(captured_output, message) when captured_output == "", do: message
  defp build_error_message(captured_output, message), do: captured_output <> "\n" <> message

  def handle_anonymous_result(job, status, message) do
    job_name =
      case job.name do
        name when is_atom(name) -> Atom.to_string(name)
        name -> name
      end

    CronyxJobRuns.add_job_run(job_name, status, message)
  end

  defp handle_execution_result(job, status, message) do
    CronyxJobs.update_last_run(job.id)
    CronyxJobs.update_job_status(job.id, status)
    CronyxJobRuns.add_job_run(job, status, message)
  end
end
