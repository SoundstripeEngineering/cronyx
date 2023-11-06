defmodule Cronyx.QueueManager do
  use GenServer

  alias Cronyx.Db.CronyxJobs
  alias Cronyx.Cron.Expression, as: CronTab

  @retry_interval 1_000
  @initial_state {:queue.new(), false}

  def start_link(opts \\ []) do
    IO.puts("[ENTER] QueueManager.start_link()")
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
  end

  def init(:ok) do
    if Cronyx.Repo.repo_ready?() do
      handle_initialization()
    else
      Process.send_after(self(), :check_repo_ready, @retry_interval)

      {:ok, @initial_state}
    end
  end

  def add_job(job) do
    GenServer.cast(__MODULE__, {:add_job, job})
  end

  def handle_cast({:add_job, job}, {queue, processing}) do
    new_state = :queue.in(job, queue)

    # Resume the processing loop if not already processing
    unless processing do
      send(self(), :dispatch_job)
    end

    {:noreply, {new_state, true}}
  end

  def handle_info(:check_repo_ready, _state) do
    if Cronyx.Repo.repo_ready?() do
      handle_initialization()

      {:noreply, {:queue.new(), true}}
    else
      Process.send_after(self(), :check_repo_ready, @retry_interval)

      {:noreply, @initial_state}
    end
  end

  def handle_info(:fetch_jobs, state) do
    CronyxJobs.list_valid_jobs()
    |> Enum.each(&process_valid_job/1)

    {:noreply, state}
  end

  def handle_info(:dispatch_job, {queue, _processing}) do
    case get_next_job(queue) do
      {job, new_queue} when is_struct(job) ->
        process_next_job(job)
        send(self(), :dispatch_job)

        {:noreply, {new_queue, true}}

      {:empty, _} ->
        {:noreply, {queue, false}}
    end
  end

  defp handle_initialization() do
    # Initialize Job Queue
    send(self(), :fetch_jobs)

    # Start Queue Refresh
    :timer.send_interval(fetch_interval() * 1_000, :fetch_jobs)

    # Start the Dispatch Loop Immediately
    send(self(), :dispatch_job)
  end

  defp process_valid_job(job) do
    parsed_command = parse_job_command(job.command)

    add_job(%Cronyx.PersistedJob{
      id: job.id,
      name: job.name,
      description: job.description,
      schedule: job.schedule,
      module: parsed_command.mod_atom,
      function: parsed_command.func_atom,
      args: parsed_command.arguments,
      last_run_at: nil
    })
  end

  defp process_next_job(%Cronyx.PersistedJob{} = job), do: dispatch(job)

  defp process_next_job(%Cronyx.ManualJob{} = job) do
    job = dispatch(job)
    current_time = Time.utc_now()
    elapsed_seconds = 60 - current_time.second
    :timer.sleep(elapsed_seconds * 1_000)
    add_job(job)
  end

  defp process_next_job(_), do: IO.puts("IT IS AN UNKNOWN JOB TYPE")

  def get_next_job(state) do
    case :queue.out(state) do
      {{:value, value}, new_state} -> {value, new_state}
      # Handle empty queue case
      {:empty, _} -> {:empty, state}
    end
  end

  defp dispatch(job) do
    if should_run?(job) do
      spawn(fn ->
        :poolboy.transaction(:worker_pool, fn pid ->
          Cronyx.Worker.execute_job(pid, job)
        end)
      end)

      Map.put(job, :last_run_at, DateTime.utc_now())
    else
      job
    end
  end

  defp should_run?(%{schedule: schedule, last_run_at: last_run_at}) do
    CronTab.now?(CronTab.parse!(schedule)) &&
      (is_nil(last_run_at) ||
         truncate_to_minute(DateTime.utc_now()) > truncate_to_minute(last_run_at))
  end

  defp truncate_to_minute(%DateTime{
         year: year,
         month: month,
         day: day,
         hour: hour,
         minute: minute,
         time_zone: time_zone,
         zone_abbr: zone_abbr,
         utc_offset: utc_offset,
         std_offset: std_offset
       }) do
    %DateTime{
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: 0,
      microsecond: {0, 0},
      time_zone: time_zone,
      zone_abbr: zone_abbr,
      utc_offset: utc_offset,
      std_offset: std_offset
    }
  end

  defp parse_job_command(command) do
    regex = ~r/^(.*\.)([^\.()]+)(?:\(\s*([^)]*?)\s*\))?$/

    case Regex.scan(regex, command) do
      [[_, module, func, args | _]] ->
        module = "Elixir." <> String.trim_trailing(module, ".")

        args_list = Enum.map(String.split(args, ",", trim: true), &parse_arg(&1))

        %{
          mod_atom: String.to_atom(module),
          func_atom: String.to_atom(func),
          arguments: args_list
        }

      [[_, module, func]] ->
        module = "Elixir." <> String.trim_trailing(module, ".")

        %{
          mod_atom: String.to_atom(module),
          func_atom: String.to_atom(func),
          arguments: []
        }

      _ ->
        %{
          mod_atom: nil,
          func_atom: nil,
          arguments: nil
        }
    end
  end

  defp parse_arg(arg) do
    arg = String.trim(arg)

    cond do
      arg == "true" ->
        true

      arg == "false" ->
        false

      Regex.match?(~r/^:\w+$/, arg) ->
        arg |> String.trim() |> String.trim_leading(":") |> String.to_atom()

      Regex.match?(~r/^[‘’'“”"]+.*[‘’'“”"]+$/, arg) ->
        arg
        |> String.trim("“")
        |> String.trim("”")
        |> String.trim("‘")
        |> String.trim("’")
        |> String.trim("'")
        |> String.trim("\"")
        |> String.trim()

      true ->
        arg |> String.trim()
    end
  end

  defp fetch_interval do
    interval = Application.get_env(:cronyx, :interval, 60)
    max(interval, 60)
  end
end
