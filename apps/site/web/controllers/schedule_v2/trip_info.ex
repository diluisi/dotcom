defmodule Site.ScheduleV2Controller.TripInfo do
  @moduledoc """

  Assigns :trip_info to either a TripInfo struct or nil, depending on whether
  there's a trip we want to display.

  """
  @behaviour Plug
  alias Plug.Conn
  import Plug.Conn, only: [assign: 3, halt: 1]
  import Phoenix.Controller, only: [redirect: 2]
  import UrlHelpers, only: [update_url: 2]

  require Routes.Route
  alias Routes.Route

  @default_opts [
    trip_fn: &Schedules.Repo.schedule_for_trip/1,
    vehicle_fn: &Vehicles.Repo.trip/1,
    prediction_fn: &Predictions.Repo.all/1
  ]

  def init(opts) do
    Keyword.merge(@default_opts, opts)
  end

  def call(conn, opts) do
    case trip_id(conn) do
      nil ->
        assign(conn, :trip_info, nil)
        |> assign(:vehicle_status, nil)
      selected_trip_id ->
        handle_trip(conn, selected_trip_id, conn.query_params["origin"], conn.query_params["destination"], collapse?(conn), opts)
        |> handle_vehicle_status(selected_trip_id, opts)
    end
  end


  # Returns the selected trip ID based on the conn's query params or stop times.
  @spec trip_id(Conn.t) :: String.t | nil
  defp trip_id(%Conn{query_params: %{"trip" => trip_id}}) do
    trip_id
  end
  defp trip_id(%Conn{assigns:
                %{stop_times: %StopTimeList{times: times},
                  route: route,
                  date: user_selected_date,
                  date_time: date_time}}) when times != [] do
    if show_trips?(user_selected_date, date_time, route.type) do
      current_trip(times, date_time)
    else
      nil
    end
  end
  defp trip_id(%Conn{assigns: %{stop_times: %StopTimeList{times: times}, date_time: date_time}}) when times != [] do
    current_trip(times, date_time)
  end
  defp trip_id(%Conn{}) do
    nil
  end

  # Checks if trips should be collapsed, based on the conn.
  @spec collapse?(Conn.t) :: boolean
  defp collapse?(conn) do
    is_nil(conn.query_params["show_collapsed_trip_stops?"])
  end

  defp handle_vehicle_status(%Conn{assigns: %{vehicle_locations: vehicle_locations}} = conn, selected_trip_id, opts) do
    vehicle_status = case build_info(selected_trip_id, conn, nil, nil, false, opts) do
      {:error, _} ->
        url = update_url(conn, trip: nil)
        conn
        |> redirect(to: url)
        |> halt
      info ->
        Enum.find_value info.sections, fn section ->
          Enum.find_value section, fn item ->
            case item.schedule do
              nil ->
                false
              _ ->
                case item.schedule.trip do
                  nil ->
                    false
                  _ ->
                    vehicle = vehicle_locations[{item.schedule.trip.id, item.schedule.stop.id}]
                    if vehicle do
                      %{stop_name: item.schedule.stop.name, vehicle: vehicle, route_type: info.route.type}
                    end
                end
            end
          end
        end
    end
    assign(conn, :vehicle_status, vehicle_status)
  end
  defp handle_vehicle_status(conn, _selected_trip_id, _opts) do
    assign(conn, :vehicle_status, nil)
  end

  defp handle_trip(conn, selected_trip_id, origin, destination, collapse, opts) do
    case build_info(selected_trip_id, conn, origin, destination, collapse, opts) do
      {:error, _} ->
        url = update_url(conn, trip: nil)
        conn
        |> redirect(to: url)
        |> halt
      info ->
        assign(conn, :trip_info, info)
    end
  end

  defp build_info(trip_id, conn, origin, destination, collapse, opts) do
    trip_id
    |> opts[:trip_fn].()
    |> build_trip_times(conn.assigns, trip_id, opts[:prediction_fn])
    |> TripInfo.from_list(
      collapse?: collapse,
      vehicle: opts[:vehicle_fn].(trip_id),
      origin_id: origin,
      destination_id: destination)
  end

  # If there are more trips left in a day, finds the next trip based on the current time.
  @spec current_trip([StopTime.t], DateTime.t) :: String.t | nil
  defp current_trip([%StopTime{} | _] = times, now) do
    do_current_trip times, now
  end
  defp current_trip([], _now), do: nil

  @spec do_current_trip([StopTime.t], DateTime.t) :: String.t | nil
  defp do_current_trip(times, now) do
    case Enum.find(times, &is_trip_after_now?(&1, now)) do
      nil -> nil
      time -> PredictedSchedule.trip(time.departure).id
    end
  end

  @spec is_trip_after_now?(StopTime.t, DateTime.t) :: boolean
  defp is_trip_after_now?(%StopTime{departure: departure}, now) do
    # returns true if the StopTime has a trip that's departing in the future
    PredictedSchedule.map_optional(departure, [:schedule, :prediction], false, fn x ->
      if x.time && x.trip do
        Timex.after?(x.time, now)
      else
        false
      end
    end)
  end

  defp build_trip_times(schedules, %{date_time: date_time} = assigns, trip_id, prediction_fn) do
    assigns
    |> get_trip_predictions(Util.service_date(date_time), trip_id, prediction_fn)
    |> PredictedSchedule.group_by_trip(schedules)
  end

  defp get_trip_predictions(%{date: date}, service_date, _, _prediction_fn)
  when date != service_date do
    []
  end
  defp get_trip_predictions(_, _, trip_id, prediction_fn) do
    prediction_fn.([trip: trip_id])
  end

  @spec show_trips?(DateTime.t, DateTime.t, integer) :: boolean
  def show_trips?(user_selected_date, current_date_time, route_type) when Route.subway?(route_type) do
    Timex.diff(user_selected_date, current_date_time, :days) == 0
  end
  def show_trips?(_date, _current_date_time, _route_type), do: true
end
