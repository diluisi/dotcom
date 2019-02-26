defmodule Site.TransitNearMe do
  @moduledoc """
  Struct and helper functions for gathering data to use on TransitNearMe.
  """

  alias Alerts.{Alert, InformedEntity, Match}
  alias GoogleMaps.Geocode.Address
  alias PredictedSchedule.Display
  alias Predictions.Prediction
  alias Routes.Route
  alias Schedules.{Schedule, Trip}
  alias SiteWeb.Router.Helpers
  alias SiteWeb.ViewHelpers
  alias Stops.{Nearby, Stop}
  alias Util.Distance

  defstruct location: nil,
            stops: [],
            distances: %{},
            schedules: %{}

  @type schedule_data :: %{
          Route.id_t() => %{
            Trip.headsign() => Schedule.t()
          }
        }

  @type distance_hash :: %{Stop.id_t() => float}

  @type t :: %__MODULE__{
          location: Address.t() | nil,
          stops: [Stop.t()],
          distances: distance_hash,
          schedules: %{Stop.id_t() => schedule_data}
        }

  @type error :: {:error, :timeout | :no_stops}

  @default_opts [
    stops_nearby_fn: &Nearby.nearby/1,
    schedules_fn: &Schedules.Repo.schedule_for_stop/2
  ]

  @spec build(Address.t(), Keyword.t()) :: t() | error
  def build(%Address{} = location, opts) do
    opts = Keyword.merge(@default_opts, opts)
    nearby_fn = Keyword.fetch!(opts, :stops_nearby_fn)

    with {:stops, [%Stop{} | _] = stops} <- {:stops, nearby_fn.(location)},
         {:schedules, {:ok, schedules}} <- {:schedules, get_schedules(stops, opts)} do
      %__MODULE__{
        location: location,
        stops: stops,
        schedules: schedules,
        distances: Map.new(stops, &{&1.id, Distance.haversine(&1, location)})
      }
    end
  end

  @spec get_schedules([Stop.t()], Keyword.t()) ::
          {:ok, %{Stop.id_t() => [Schedule.t()]}} | {:error, :timeout}
  defp get_schedules(stops, opts) do
    schedules_fn = Keyword.fetch!(opts, :schedules_fn)
    now = Keyword.fetch!(opts, :now)

    min_time = format_min_time(now)

    stops
    |> Task.async_stream(
      fn stop ->
        {
          stop.id,
          stop.id
          |> schedules_fn.(min_time: min_time)
          |> Enum.reject(& &1.last_stop?)
        }
      end,
      on_timeout: :kill_task
    )
    |> Enum.reduce_while({:ok, %{}}, &collect_data/2)
  end

  def format_min_time(%DateTime{hour: hour, minute: minute}) do
    format_min_hour(hour) <> ":" <> format_time_integer(minute)
  end

  defp format_min_hour(hour) when hour in [0, 1, 2] do
    # use integer > 24 to return times after midnight for the service day
    Integer.to_string(24 + hour)
  end

  defp format_min_hour(hour) do
    format_time_integer(hour)
  end

  defp format_time_integer(num) when num < 10 do
    "0" <> Integer.to_string(num)
  end

  defp format_time_integer(num) do
    Integer.to_string(num)
  end

  @spec collect_data({:ok, any} | {:exit, :timeout}, {:ok, map | [any]}) ::
          {:cont, {:ok, map | [any]}} | {:halt, {:error, :timeout}}
  defp collect_data({:ok, {key, value}}, {:ok, %{} = acc}) do
    {:cont, {:ok, Map.put(acc, key, value)}}
  end

  defp collect_data({:ok, value}, {:ok, acc}) when is_list(acc) do
    {:cont, {:ok, [value | acc]}}
  end

  defp collect_data({:exit, :timeout}, _) do
    {:halt, {:error, :timeout}}
  end

  @spec sort_by_time({:ok, [{DateTime.t() | nil, any}]} | {:error, :timeout}) ::
          {DateTime.t() | nil, [any]}
  defp sort_by_time({:error, :timeout}) do
    {nil, []}
  end

  defp sort_by_time({:ok, []}) do
    {nil, []}
  end

  defp sort_by_time({:ok, list}) do
    {[closest_time | _], sorted} =
      list
      |> Enum.sort_by(fn {time, _data} -> time end)
      |> Enum.unzip()

    {closest_time, sorted}
  end

  @doc """
  Builds a list of routes that stop at a Stop.
  """
  @spec routes_for_stop(t(), Stop.id_t()) :: [Route.t()]
  def routes_for_stop(%__MODULE__{schedules: schedules}, stop_id) do
    schedules
    |> Map.fetch!(stop_id)
    |> Enum.reduce(MapSet.new(), &MapSet.put(&2, &1.route))
    |> MapSet.to_list()
  end

  @doc """
  Returns the distance of a stop from the input location.
  """
  @spec distance_for_stop(t(), Stop.id_t()) :: float
  def distance_for_stop(%__MODULE__{distances: distances}, stop_id) do
    Map.fetch!(distances, stop_id)
  end

  @type simple_prediction :: %{
          required(:time) => [String.t()],
          required(:status) => String.t() | nil,
          required(:track) => String.t() | nil
        }

  @type time_data :: %{
          required(:scheduled_time) => [String.t()],
          required(:prediction) => simple_prediction | nil
        }

  @type headsign_data :: %{
          required(:name) => String.t(),
          required(:times) => [time_data],
          required(:train_number) => String.t() | nil
        }

  @type direction_data :: %{
          required(:direction_id) => 0 | 1,
          required(:headsigns) => [headsign_data]
        }

  @type stop_data :: %{
          # stop_data includes the full %Stop{} struct, plus:
          required(:directions) => [direction_data],
          required(:distance) => String.t(),
          required(:href) => String.t()
        }

  @type route_data :: %{
          # route_data includes the full %Route{} struct, plus:
          required(:stops) => [stop_data],
          required(:alert_count) => integer
        }

  @doc """
  Uses the schedules to build a list of route objects, which each have
  a list of stops. Each stop has a list of directions. Each direction has a
  list of headsigns. Each headsign has a schedule, and a prediction if available.
  """
  @spec schedules_for_routes(t(), [Alert.t()], Keyword.t()) :: [route_data]
  def schedules_for_routes(
        %__MODULE__{
          schedules: schedules,
          location: location,
          distances: distances
        },
        alerts,
        opts \\ []
      ) do
    schedules
    |> Map.values()
    |> List.flatten()
    |> Enum.filter(&coming_today_if_bus(&1, &1.route.type))
    |> Enum.group_by(& &1.route.id)
    |> Enum.map(&schedules_for_route(&1, location, distances, alerts, opts))
    |> Enum.sort_by(&route_sorter(&1, distances))
  end

  @spec coming_today_if_bus(Schedule.t(), 0..4) :: boolean
  defp coming_today_if_bus(schedule, 3) do
    twenty_four_hours_in_seconds = 86_400

    DateTime.diff(schedule.time, Util.now()) < twenty_four_hours_in_seconds
  end

  defp coming_today_if_bus(_schedule, _non_bus_route_type) do
    true
  end

  defp route_sorter(%{stops: [%{id: stop_id} | _]}, distances) do
    Map.fetch!(distances, stop_id)
  end

  @spec schedules_for_route(
          {Route.id_t(), [Schedule.t()]},
          Address.t(),
          distance_hash,
          [Alert.t()],
          Keyword.t()
        ) :: route_data
  defp schedules_for_route({_route_id, schedules}, location, distances, alerts, opts) do
    [%Schedule{route: route} | _] = schedules

    route
    |> Map.from_struct()
    |> Map.update!(:direction_names, fn map ->
      Map.new(map, fn {key, val} -> {Integer.to_string(key), Route.add_direction_suffix(val)} end)
    end)
    |> Map.update!(:direction_destinations, fn map ->
      Map.new(map, fn {key, val} -> {Integer.to_string(key), val} end)
    end)
    |> Map.update!(:name, fn name -> ViewHelpers.break_text_at_slash(name) end)
    |> Map.put(:stops, get_stops_for_route(schedules, location, distances, opts))
    |> Map.put(:alert_count, get_alert_count_for_route(route, alerts))
  end

  @spec get_alert_count_for_route(Route.t(), [Alert.t()]) :: integer
  defp get_alert_count_for_route(route, alerts) do
    alerts |> Match.match([%InformedEntity{route: route.id}]) |> length()
  end

  @spec get_stops_for_route([Schedule.t()], Address.t(), distance_hash, Keyword.t()) :: [
          stop_data
        ]
  defp get_stops_for_route(schedules, location, distances, opts) do
    schedules
    |> Enum.group_by(& &1.stop.id)
    |> Task.async_stream(&get_directions_for_stop(&1, location, opts), on_timeout: :kill_task)
    |> Enum.reduce_while({:ok, []}, &collect_data/2)
    |> case do
      {:error, :timeout} -> []
      {:ok, results} -> Enum.sort_by(results, &Map.fetch!(distances, &1.id))
    end
  end

  @spec get_directions_for_stop({Stop.id_t(), [Schedule.t()]}, Address.t(), Keyword.t()) ::
          stop_data
  defp get_directions_for_stop({_stop_id, schedules}, location, opts) do
    [%Schedule{stop: schedule_stop} | _] = schedules
    stop_fn = Keyword.get(opts, :stops_fn, &Stops.Repo.get/1)
    stop = stop_fn.(schedule_stop.id)

    distance = Distance.haversine(stop, location)
    href = Helpers.stop_path(SiteWeb.Endpoint, :show, stop.id)

    stop
    |> Map.from_struct()
    |> Map.put(:directions, get_direction_map(schedules, opts))
    |> Map.put(:distance, ViewHelpers.round_distance(distance))
    |> Map.put(:href, href)
  end

  @spec get_direction_map([Schedule.t()], Keyword.t()) :: [direction_data]
  defp get_direction_map(schedules, opts) do
    schedules
    |> Enum.group_by(& &1.trip.direction_id)
    |> Task.async_stream(&build_direction_map(&1, opts), on_timeout: :kill_task)
    |> Enum.reduce_while({:ok, []}, &collect_data/2)
    |> sort_by_time()
    |> elem(1)
  end

  @spec build_direction_map({0 | 1, [Schedule.t()]}, Keyword.t()) ::
          {DateTime.t(), direction_data}
  defp build_direction_map({direction_id, schedules}, opts) do
    {closest_time, headsigns} =
      schedules
      |> Enum.group_by(& &1.trip.headsign)
      |> Task.async_stream(&build_headsign_map(&1, opts), on_timeout: :kill_task)
      |> Enum.reduce_while({:ok, []}, &collect_data/2)
      |> sort_by_time()

    {
      closest_time,
      %{
        direction_id: direction_id,
        headsigns: headsigns
      }
    }
  end

  @spec build_headsign_map({Schedules.Trip.headsign(), [Schedule.t()]}, Keyword.t()) ::
          {DateTime.t(), headsign_data}
  defp build_headsign_map({headsign, schedules}, opts) do
    [%{route: route, trip: trip} | _] = schedules

    {times, headsign_schedules} =
      schedules
      |> Enum.take(schedule_count(route))
      |> Enum.map(&build_time_map(&1, opts))
      |> filter_headsign_schedules()
      |> Enum.unzip()

    {
      get_closest_time_for_headsign(times),
      %{
        name: ViewHelpers.break_text_at_slash(headsign),
        times: headsign_schedules,
        train_number: trip.name
      }
    }
  end

  defp get_closest_time_for_headsign([{nil, %DateTime{} = schedule} | _]), do: schedule

  defp get_closest_time_for_headsign([{%DateTime{} = pred, %DateTime{}} | _]), do: pred

  defp schedule_count(%Route{type: 2}), do: 1
  defp schedule_count(%Route{}), do: 2

  @type predicted_schedule_and_time_data :: {{DateTime.t() | nil, DateTime.t()}, time_data}

  @spec filter_headsign_schedules([predicted_schedule_and_time_data]) :: [
          predicted_schedule_and_time_data
        ]
  defp filter_headsign_schedules([{{_, _}, _} = keep, {{nil, _}, _}]) do
    # only show one schedule if the second schedule has no prediction
    [keep]
  end

  defp filter_headsign_schedules(schedules) do
    schedules
  end

  @spec build_time_map(Schedule.t(), Keyword.t()) :: predicted_schedule_and_time_data
  defp build_time_map(schedule, opts) do
    route_type = Route.type_atom(schedule.route)
    predictions_fn = Keyword.get(opts, :predictions_fn, &Predictions.Repo.all/1)

    prediction =
      [trip: schedule.trip.id]
      |> predictions_fn.()
      # occasionally, a prediction will not have a time; discard if that happens
      |> Enum.filter(& &1.time)
      |> case do
        [] -> nil
        [prediction | _] -> prediction
      end

    {
      {prediction_time(prediction), schedule.time},
      %{
        scheduled_time: format_time(schedule.time),
        prediction: simple_prediction(prediction, route_type)
      }
    }
  end

  defp prediction_time(nil), do: nil
  defp prediction_time(%Prediction{time: time}), do: time

  @spec simple_prediction(Prediction.t() | nil, atom) :: simple_prediction | nil
  def simple_prediction(nil, _) do
    nil
  end

  def simple_prediction(%Prediction{} = prediction, route_type) do
    prediction
    |> Map.update!(:time, &format_prediction_time(&1, route_type))
    |> Map.take([:time, :status, :track])
  end

  @spec format_prediction_time(DateTime.t(), atom) :: [String.t()] | String.t()
  defp format_prediction_time(%DateTime{} = time, :commuter_rail) do
    format_time(time)
  end

  defp format_prediction_time(%DateTime{} = time, _) do
    Display.do_time_difference(time, Util.now(), &format_time/1)
  end

  @spec format_time(DateTime.t()) :: [String.t()]
  defp format_time(time) do
    [time, am_pm] =
      time
      |> Timex.format!("{h12}:{m} {AM}")
      |> String.split(" ")

    [time, " ", am_pm]
  end
end
