defmodule Stops.Repo do
  @moduledoc """
  Matches the Ecto API, but fetches Stops from the Stop Info API instead.
  """
  use RepoCache, ttl: :timer.hours(1)
  alias Stops.Position
  alias Stops.Stop

  def stations do
    cache [], fn _ ->
      Stops.Api.all
      |> Enum.sort_by(&(&1.name))
    end
  end

  def get(id) do
    cache id, &Stops.Api.by_gtfs_id/1
  end

  def get!(id) do
    case get(id) do
      nil -> raise Stops.NotFoundError, message: "Could not find stop #{id}"
      stop -> stop
    end
  end

  @spec closest(Position.t) :: [Stop.t]
  def closest(position) do
    Stops.Nearby.nearby(position)
  end

  @spec by_route(Routes.Route.id_t, 0 | 1, Keyword.t) :: [Stop.t] | {:error, any}
  def by_route(route_id, direction_id, opts \\ []) do
    cache {route_id, direction_id, opts}, &Stops.Api.by_route/1
  end

  @spec by_routes([Routes.Route.id_t], 0 | 1, Keyword.t) :: [Stop.t] | {:error, any}
  def by_routes(route_ids, direction_id, opts \\ []) when is_list(route_ids) do
    # once the V3 API supports multiple route_ids in this field, we can do it
    # as a single lookup -ps
    route_ids
    |> Task.async_stream(&by_route(&1, direction_id, opts))
    |> Enum.flat_map(fn
      {:ok, stops} -> stops
      _ -> []
    end)
    |> Enum.uniq
  end

  @spec by_route_type(Routes.Route.type, Keyword.t):: [Stop.t] | {:error, any}
  def by_route_type(route_type, opts \\ []) do
    cache {route_type, opts}, &Stops.Api.by_route_type/1
  end

  def stop_exists_on_route?(stop_id, route, direction_id) do
    route
    |> by_route(direction_id)
    |> Enum.any?(&(&1.id == stop_id))
  end
end

defmodule Stops.NotFoundError do
  @moduledoc "Raised when we don't find a stop with the given GTFS ID"
  defexception [:message]
end
