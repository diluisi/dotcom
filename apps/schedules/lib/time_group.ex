defmodule TimeGroup do
  alias Schedules.Schedule

  @doc """
  Given a list of schedules, returns those schedules grouped by the hour of day.

  Returns a keyword list rather than a map so that the times appear in order.

  Precondition: the schedules are already sorted by time.
  """
  @spec by_hour([%Schedule{}]) :: [{non_neg_integer, [%Schedule{}]}]
  def by_hour(schedules) do
    do_by_fn(schedules, &(&1.time.hour))
  end

  @doc """
  Given a list of schedules, returns those schedules grouped into subway schedule periods:
  * AM Rush Hour: OPEN - 9:00 AM (:am_rush)
  * Midday: 9:00 AM - 3:30 PM (:midday)
  * PM Rush Hour: 3:30 PM - 6:30 PM (:pm_rush)
  * Evening: 6:30 PM - 8:00 PM (:evening)
  * Late Night: 8:00 PM - CLOSE (:late_night)

  Returns a keyword list, and expects that the schedules are already sorted.
  """
  @type subway_schedule :: :am_rush|:midday|:pm_rush|:evening|:late_night
  @spec by_subway_period([%Schedule{}]) :: %{subway_schedule: [%Schedule{}]}
  def by_subway_period(schedules) do
    schedules
    |> do_by_fn(&subway_period/1)
  end

  @doc """
  Given a list of schedules, return the frequency of service in minutes.
  If there are multiple schedules, returns either a min/max pair if there's a
  variation, or a single integer.  Otherwise, returns nil.
  """
  @spec frequency([%Schedule{}]) :: {non_neg_integer, non_neg_integer} | non_neg_integer | nil
  def frequency([_,_|_] = schedules) do
    {min, max} = schedules
    |> Enum.zip(Enum.drop(schedules, 1))
    |> Enum.map(fn {x, y} -> Timex.diff(x.time, y.time, :minutes) end)
    |> Enum.min_max

    case {min, max} do
      {value, value} -> value
      _ -> {min, max}
    end
  end
  def frequency(_) do
    nil
  end

  defp do_by_fn([], _) do
    []
  end
  defp do_by_fn(schedules, func) do
    schedules
    |> Enum.reduce([], &(reduce_by_fn(&1, &2, func)))
    |> reverse_first_group
    |> Enum.reverse
  end

  defp reduce_by_fn(schedule, [], func) do
    [{func.(schedule), [schedule]}]
  end
  defp reduce_by_fn(schedule, [{value, grouped}|rest], func) do
    if value == func.(schedule) do
      head = {value, [schedule|grouped]}
      [head|rest]
    else
      head = {func.(schedule), [schedule]}
      previous_head = {value, Enum.reverse(grouped)}
      [head,previous_head|rest]
    end
  end

  defp reverse_first_group([{value, grouped}|rest]) do
    head = {value, Enum.reverse(grouped)}
    [head|rest]
  end

  @start {4, 0}
  @am_rush_end {9, 0}
  @midday_end {15, 30}
  @pm_rush_end {18, 30}
  @evening_end {20, 0}
  defp subway_period(%Schedule{time: time}) do
    tup = {time.hour, time.minute}
    cond do
      @start < tup && tup <= @am_rush_end ->
        :am_rush
      @am_rush_end < tup && tup <= @midday_end ->
        :midday
      @midday_end < tup && tup <= @pm_rush_end ->
        :pm_rush
      @pm_rush_end < tup && tup <= @evening_end ->
        :evening
      true ->
        :late_night
    end
  end
end
