defmodule Site.GreenLine.DateAgent do
  @moduledoc """
  This is a supervised agent storing the cached results of a function for a given
  date.
  """

  import GreenLine, only: [calculate_stops_on_routes: 2]

  def stops_on_routes(pid, direction_id) do
    Agent.get(pid, fn state -> elem(state, direction_id) end)
  end

  def reset(pid, date, calculate_state_fn \\ &calculate_state/1) do
    Agent.update(pid, fn _ -> calculate_state_fn.(date) end)
  end

  def start_link(date, calculate_state_fn \\ &calculate_state/1) do
    Agent.start_link(fn -> calculate_state_fn.(date) end, name: via_tuple(date))
  end

  def lookup(date) do
    case Registry.lookup(:green_line_cache_registry, date) do
      [{pid, _}] -> pid
      _ -> nil
    end
  end

  defp calculate_state(date) do
    {calculate_stops_on_routes(0, date), calculate_stops_on_routes(1, date)}
  end

  defp via_tuple(date) do
    {:via, Registry, {:green_line_cache_registry, date}}
  end
end
