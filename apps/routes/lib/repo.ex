defmodule Routes.Repo do
  use RepoCache, ttl: :timer.hours(24)

  import Routes.Parser

  @doc """

  Returns a list of all the routes

  """
  @spec all() :: [Routes.Route.t]
  def all do
    cache [], fn _ ->
      V3Api.Routes.all
      |> handle_response
    end
  end

  @doc """

  Returns a single route by ID

  """
  @spec get(String.t) :: Routes.Route.t | nil
  def get(id) do
    all()
    |> Enum.find(fn
      %{id: ^id} -> true
      _ -> false
    end)
  end

  @doc """

  Given a route_type (or list of route types), returns the list of routes matching that type.

  """
  @spec by_type([0..4] | 0..4) :: [Routes.Route.t]
  def by_type(types) when is_list(types) do
    all()
    |> Enum.filter(fn %{type: type} ->
      type in types
    end)
  end
  def by_type(type) do
    all()
    |> Enum.filter(&match?(%{type: ^type}, &1))
  end

  @doc """

  Given a stop ID, returns the list of routes which stop there.

  """
  @spec by_stop(String.t) :: [Routes.Route.t]
  def by_stop(stop_id, opts \\ []) do
    {:ok, routes} = cache {stop_id, opts}, fn {stop_id, opts} ->
      {:ok, stop_id
      |> V3Api.Routes.by_stop(opts)
      |> handle_response
      }
    end
    routes
  end

  @doc """

  Given a route_id, returns a map with the headsigns for trips in the given
  directions (by direction_id).

  """
  @spec headsigns(String.t) :: %{0 => [String.t], 1 => [String.t]}
  def headsigns(id) do
    cache id, fn id ->
      [zero_task, one_task] = for direction_id <- [0, 1] do
        Task.async(__MODULE__, :do_headsigns, [id, direction_id])
      end
      %{
        0 => Task.await(zero_task),
        1 => Task.await(one_task)
      }
    end
  end

  @spec do_headsigns(String.t, non_neg_integer) :: any
  def do_headsigns(route_id, direction_id) do
    route_id
    |> V3Api.Trips.by_route("fields[trip]": "headsign", direction_id: direction_id)
    |> (fn %{data: data} -> data end).()
    |> Enum.filter_map(
      fn %{attributes: attributes} -> attributes["headsign"] != "" end,
      fn %{attributes: attributes} -> attributes["headsign"] end
    )
    |> order_by_frequency
  end

  defp handle_response(%{data: data}) do
    data
    |> Enum.reject(&hidden_routes/1)
    |> Enum.map(&parse_json/1)
  end

  defp hidden_routes(%{id: "746"}), do: true
  defp hidden_routes(%{id: "2427"}), do: true
  defp hidden_routes(%{id: "3233"}), do: true
  defp hidden_routes(%{id: "3738"}), do: true
  defp hidden_routes(%{id: "4050"}), do: true
  defp hidden_routes(%{id: "627"}), do: true
  defp hidden_routes(%{id: "725"}), do: true
  defp hidden_routes(%{id: "8993"}), do: true
  defp hidden_routes(%{id: "116117"}), do: true
  defp hidden_routes(%{id: "214216"}), do: true
  defp hidden_routes(%{id: "441442"}), do: true
  defp hidden_routes(%{id: "9701"}), do: true
  defp hidden_routes(%{id: "9702"}), do: true
  defp hidden_routes(%{id: "9703"}), do: true
  defp hidden_routes(%{id: "Logan-" <> _}), do: true
  defp hidden_routes(%{id: "CapeFlyer"}), do: true
  defp hidden_routes(_), do: false

  defp order_by_frequency(enum) do
    # the complicated function in the middle collapses some lengths which are
    # close together and allows us to instead sort by the name.  For example,
    # on the Red line, Braintree has 649 trips, Ashmont has 647.  The
    # division by -4 with a round makes them both -162 and so equal.  We
    # divide by -4 so that the ordering by count is large to small, but the
    # name ordering is small to large.
    enum
    |> Enum.group_by(&(&1))
    |> Enum.sort_by(fn {value, values} -> {
      values
      |> length
      |> (fn v -> Float.round(v / -4) end).(), value}
    end)
    |> Enum.map(&(elem(&1, 0)))
  end
end
