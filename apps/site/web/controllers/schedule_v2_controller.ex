defmodule Site.ScheduleV2Controller do
  use Site.Web, :controller

  plug Site.Plugs.Route, required: true
  plug Site.Plugs.Date
  plug Site.Plugs.DateTime
  plug Site.ScheduleController.DatePicker
  plug Site.Plugs.Alerts
  plug Site.ScheduleV2Controller.Defaults
  plug Site.ScheduleController.AllStops
  plug Site.ScheduleV2Controller.OriginDestination
  plug Site.ScheduleV2Controller.Schedules
  plug Site.ScheduleV2Controller.VehicleLocations
  plug Site.ScheduleV2Controller.Predictions
  plug Site.ScheduleController.Headsigns
  plug Site.ScheduleV2Controller.ExcludedStops
  plug Site.ScheduleV2Controller.StopTimes
  plug Site.ScheduleV2Controller.TripInfo
  plug Site.ScheduleController.RouteBreadcrumbs

  def show(%Plug.Conn{assigns: %{route: %Routes.Route{type: 2}}} = conn, params) do
    conn
    |> assign(:tab, Map.get(params, "tab", "timetable"))
    |> assign(:schedule_template, "_commuter.html")
    |> tab_assigns()
    |> render("show.html")
  end
  def show(conn, _) do
    conn
    |> assign(:tab, "trip-view")
    |> assign(:schedule_template, "_default_schedule.html")
    |> render("show.html")
  end

  defp assign_trip_schedules(conn) do
    timetable_schedules = timetable_schedules(conn)
    header_schedules = header_schedules(timetable_schedules)
    trip_schedules = Map.new(timetable_schedules, & {{&1.trip.id, &1.stop.id}, &1})

    conn
    |> assign(:timetable_schedules, timetable_schedules)
    |> assign(:header_schedules, header_schedules)
    |> assign(:trip_schedules, trip_schedules)
  end

  defp timetable_schedules(%{assigns: %{date: date, route: route, direction_id: direction_id}}) do
    Schedules.Repo.all(date: date, route: route.id, direction_id: direction_id)
  end

  defp header_schedules(timetable_schedules) do
    timetable_schedules
    |> Schedules.Sort.sort_by_first_times
    |> Enum.map(&List.first/1)
  end

  defp tab_assigns(%Plug.Conn{assigns: %{tab: "timetable"}} = conn) do
    conn
    |> assign_trip_schedules
    |> call_plug(Site.ScheduleV2Controller.Offset)
  end
  defp tab_assigns(%Plug.Conn{assigns: %{tab: "trip-view", all_stops: all_stops}} = conn) do
    assign(conn, :zone_map, Map.new(all_stops, &{&1.id, Zones.Repo.get(&1.id)}))
  end

  defp call_plug(conn, module) do
    module.call(conn, module.init([]))
  end
end
