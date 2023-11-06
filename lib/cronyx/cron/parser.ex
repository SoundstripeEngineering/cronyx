defmodule Cronyx.Cron.Parser do
  @moduledoc false

  @days_of_week [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday]

  def parse_frequency(frequency, time \\ "00:00"),
    do: frequency |> do_parse_frequency(parse_time(time))

  defp do_parse_frequency(:invalid, _), do: :invalid

  defp do_parse_frequency(frequency, time) when frequency in @days_of_week do
    format_day(frequency, time)
  end

  defp do_parse_frequency(frequency, time) when is_tuple(frequency) do
    frequency |> Tuple.to_list() |> do_parse_frequency(time)
  end

  defp do_parse_frequency(frequency, time) when is_list(frequency) do
    frequency
    |> Enum.map(fn day -> Enum.find_index(@days_of_week, fn weekday -> weekday == day end) end)
    |> format_frequency(time)
  end

  defp do_parse_frequency(frequency, {hour, minute}) do
    case frequency do
      :minute -> "* * * * *"
      :minutely -> "* * * * *"
      :hourly -> "0 * * * *"
      :daily -> "#{minute} #{hour} * * *"
      :monthly -> "#{minute} #{hour} 1 * *"
      :yearly -> "#{minute} #{hour} 1 1 *"
      :annually -> "#{minute} #{hour} 1 1 *"
      :weekdays -> "#{minute} #{hour} * * 1-5"
      :weekends -> "#{minute} #{hour} * * 6-7"
      _ -> :invalid
    end
  end

  defp format_day(day, {hour, minute}) do
    day_index = Enum.find_index(@days_of_week, &(&1 == day))
    "#{minute} #{hour} * * #{day_index}"
  end

  defp format_frequency(days, {hour, minute}) do
    formatted_days =
      case days do
        [single] -> single
        [first, second] -> "#{first}-#{second}"
        _ -> Enum.join(days, ",")
      end

    "#{minute} #{hour} * * #{formatted_days}"
  end

  def parse_interval(interval, frequency, time \\ "00:00"),
    do: do_parse_interval(interval, frequency, parse_time(time))

  defp do_parse_interval(_, _, :invalid), do: :invalid

  defp do_parse_interval(interval, frequency, time) do
    format_interval(interval, frequency, time)
  end

  defp format_interval(interval, frequency, {hour, minute}) do
    interval_str = if interval > 1, do: "*/#{interval}", else: "*"

    case frequency do
      :minute -> "#{interval_str} * * * *"
      :minutely -> "#{interval_str} * * * *"
      :hourly -> "0 #{interval_str} * * *"
      :daily -> "#{minute} #{hour} #{interval_str} * *"
      :monthly -> "#{minute} #{hour} 1 #{interval_str} *"
      _ -> :invalid
    end
  end

  defp parse_time(time) when is_bitstring(time) do
    try do
      String.split(time, ":")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    rescue
      _ -> :invalid
    end
  end
end
