defmodule Util do
  use Timex

  @doc "joins two strings together, separating them with a space"
  def string_join(s1, s2)
  def string_join("", s2), do: s2
  def string_join(s1, ""), do: s1
  def string_join(s1, s2), do: s1 <> " " <> s2

  @doc "Given a list of values, return the one which appears the most"
  def most_frequent_value(values) do
    values
    |> Enum.group_by(&(&1))
    |> Enum.into([])
    |> Enum.max_by(fn {_, items} -> length(items) end)
    |> elem(0)
  end

  @doc "The current datetime in the America/New_York timezone."
  def now do
    Timex.now("America/New_York")
  end

  @doc "Today's date in the America/New_York timezone."
  def today do
    now |> Timex.to_date
  end

  @doc """

  The current service date.  The service date lasts from 3am to 2:59am, so
  times after midnight belong to the service of the previous date.

  """
  def service_date(current_time \\ nil) do
    current_time = current_time || Util.now

    current_time
    |> Timex.shift(hours: -3)
    |> Timex.to_date
  end
end
