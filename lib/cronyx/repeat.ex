defmodule Cronyx.Repeat do
  @moduledoc """
  This module defines macros for creating ad-hoc scheduled jobs.
  These jobs are not persisted, but exist only for the duration
  of the parent application lifecycle.
  """
  import Cronyx.Cron.Parser

  @doc """
  The `Cronyx.Repeat.repeat/2` macro provides a simple interface for adding
  ad-hoc jobs

  ## Arguments:

    * `frequency` (atom) - the frequency the job should be repeated. Accepts any of the following:
            `:minutely`, `:hourly`, `:midnight`, `:daily`, `:weekly`, `:yearly`,
            `:annually`, `:weekdays`, `:weekends`
    * `args`
       - `at` (str) - the time of day when the job should execute, in the format `HH:MM`
       - `name` (str) - the name of the job, used when storing job execution details
       - `block` (block) - a code block to execute

  ## Example

    ```elixir
    repeat :daily, do: IO.puts("daily task to execute")
    # Cron Schedule generated: "0 0 * * *"
    ```

    ```elixir
    repeat :daily, at: "10:45" do
      # Cron Schedule generated: "45 10 * * *"
      # Task to perform daily at 10:45 AM
    end
    ```

    ```elixir
    repeat :weekends do
      # Cron Schedule generated: "* * * * 6-7"
      # Task to perform
    end
    ```

    ```elixir
    repeat {:tuesday, :friday} do
      # Cron Schedule generated: "* * * * 2-5
    end
    ```

    ```elixir
    repeat :weekdays, at: "11:00", name: "Daily Financial Report",
      do: ReportApp.Reports.FinancialReport.generate()
    # Cron Schedule generated: "00 11 * * 1-5"
    # Assumes `ReportApp.Reports.FinancialReport.generate()` is valid in the parent application
    ```
  """
  defmacro repeat(frequency, args) when is_atom(frequency) do
    {time, name, block} = extract_args(args)
    job_name = name || create_job_name([Atom.to_string(frequency), time])
    schedule = parse_frequency(frequency, time)

    create_job(job_name, schedule, block)
  end

  defmacro repeat(frequency, args) when is_tuple(frequency) do
    {time, name, block} = extract_args(args)
    job_name = name || create_job_name(["multiple_days", time])

    days = extract_days(frequency)
    schedule = parse_frequency(days, time)

    create_job(job_name, schedule, block)
  end

  @doc """
  The `Cronyx.Repeat.repeat/3` macro provides a simple interface for adding
  ad-hoc jobs with interval scheduling

  ## Arguments:

    * `interval` (int) - the interval frequency to apply to the schedule
    * `frequency` (atom) - the frequency the job should be repeated. Accepts any of the following:
            `:minutely`, `:hourly`, `:midnight`, `:daily`, `:weekly`, `:yearly`,
            `:annually`, `:weekdays`, `:weekends`
    * `args`
       - `at` (str) - the time of day when the job should execute, in the format `HH:MM`
       - `name` (str) - the name of the job, used when storing job execution details
       - `block` (block) - a code block to execute

  ## Example

    ```elixir
    repeat 2, :daily, do: IO.puts("execute every 2nd day of the month")
    # Cron Schedule generated: "* * */2 * *"
    ```

    ```elixir
    repeat 5, :weekly, at: "11:00" do
      # Cron Schedule generated: 00 11 * * */5
      # Task to perform every 5th day of the week at 11 AM
    ```
  """
  defmacro repeat(interval, frequency, args) when is_integer(interval) and is_atom(frequency) do
    {time, name, block} = extract_args(args)
    job_name = name || create_job_name([interval, frequency, time])
    schedule = parse_interval(interval, frequency, time)

    create_job(job_name, schedule, block)
  end

  defp extract_args(args) do
    time = Keyword.get(args, :at, "00:00")
    name = Keyword.get(args, :name)
    block = Keyword.get(args, :do)

    {time, name, block}
  end

  defp extract_days({:{}, _, list}), do: list
  defp extract_days(tuple), do: Tuple.to_list(tuple)

  defp create_job_name(parts) do
    valid_parts = Enum.filter(parts, &(not is_nil(&1)))
    "job_repeat_" <> Enum.join(valid_parts, "_")
  end

  defp create_job(job_name, schedule, block) do
    quote do
      job = %Cronyx.ManualJob{
        name: unquote(job_name),
        schedule: unquote(schedule),
        func_block: fn -> unquote(block) end
      }

      Cronyx.QueueManager.add_job(job)
    end
  end
end
