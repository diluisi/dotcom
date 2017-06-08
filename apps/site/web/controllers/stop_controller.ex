defmodule Site.StopController do
  use Site.Web, :controller

  plug :all_alerts

  alias Stops.Repo
  alias Stops.Stop
  alias Routes.Route

  @type grouped_stations :: {Route.t, [Stop.t]}

  def index(conn, _params) do
    redirect conn, to: stop_path(conn, :show, :subway)
  end

  def show(conn, %{"id" => mode}) when mode in ["subway", "commuter_rail", "ferry"] do
    mode_atom = String.to_existing_atom(mode)
    {mattapan, stop_info} = get_stop_info(mode_atom)
    conn
    |> async_assign(:mode_hubs, fn -> HubStops.mode_hubs(mode, stop_info) end)
    |> async_assign(:route_hubs, fn -> HubStops.route_hubs(stop_info) end)
    |> assign(:stop_info, stop_info)
    |> assign(:mattapan, mattapan)
    |> assign(:mode, mode_atom)
    |> assign(:breadcrumbs, ["Stations"])
    |> await_assign_all
    |> render("index.html")
  end
  def show(%Plug.Conn{query_params: query_params} = conn, %{"id" => id}) do
    stop = id
    |> URI.decode_www_form
    |> Repo.get!

    conn
    |> async_assign(:grouped_routes, fn -> grouped_routes(stop.id) end)
    |> async_assign(:zone_number, fn -> Zones.Repo.get(stop.id) end)
    |> assign(:breadcrumbs, breadcrumbs(stop))
    |> assign(:tab, tab_value(query_params["tab"]))
    |> assign(:dynamic_map_data, dynamic_map_data(stop))
    |> tab_assigns(stop)
    |> await_assign_all()
    |> render("show.html", stop: stop)
  end

  @spec dynamic_map_data(Stop.t) :: map()
  defp dynamic_map_data(stop) do
    %{
      stops: [[stop.latitude, stop.longitude, ""]],
      stops_show_marker: stop.station?,
      options: %{
        gestureHandling: "cooperative"
      }
    }
  end

  @spec grouped_routes(String.t) :: [{Route.gtfs_route_type, Route.t}]
  defp grouped_routes(stop_id) do
    stop_id
    |> Routes.Repo.by_stop
    |> Enum.group_by(&Route.type_atom/1)
    |> Enum.sort_by(&sorter/1)
  end

  @spec sorter({Route.gtfs_route_type, Route.t}) :: non_neg_integer
  defp sorter({:commuter_rail, _}), do: 0
  defp sorter({:subway, _}), do: 1
  defp sorter({:bus, _}), do: 2
  defp sorter({:ferry, _}), do: 3

  @spec breadcrumbs(Stop.t) :: [{String.t, String.t} | String.t]
  defp breadcrumbs(%Stop{station?: true, name: name}) do
    [{stop_path(Site.Endpoint, :index), "Stations"}, name]
  end
  defp breadcrumbs(%Stop{name: name}) do
    [name]
  end

  # Determine which tab should be displayed
  @spec tab_value(String.t | nil) :: String.t
  defp tab_value("schedule"), do: "schedule"
  defp tab_value(_), do: "info"

  defp tab_assigns(%{assigns: %{tab: "info", all_alerts: alerts}} = conn, stop) do
    conn
    |> async_assign(:fare_name, fn -> Fares.calculate("1A", Zones.Repo.get(stop.id)) end)
    |> async_assign(:terminal_station, fn -> terminal_station(stop) end)
    |> async_assign(:fare_sales_locations, fn -> Fares.RetailLocations.get_nearby(stop) end)
    |> assign(:access_alerts, access_alerts(alerts, stop))
    |> assign(:requires_google_maps?, true)
    |> assign(:stop_alerts, stop_alerts(alerts, stop))
    |> await_assign_all()
  end
  defp tab_assigns(%{assigns: %{tab: "schedule", all_alerts: alerts}} = conn, stop) do
    conn
    |> async_assign(:stop_schedule, fn -> stop_schedule(stop.id, conn.assigns.date) end)
    |> async_assign(:stop_predictions, fn -> stop_predictions(stop.id) end)
    |> assign(:stop_alerts, stop_alerts(alerts, stop))
    |> await_assign_all(10_000)
    |> assign_upcoming_route_departures()
  end

  defp assign_upcoming_route_departures(conn) do
    route_time_list = conn.assigns.stop_predictions
    |> UpcomingRouteDepartures.build_mode_list(conn.assigns.stop_schedule, conn.assigns.date_time)
    |> Enum.sort_by(&sorter/1)

    assign(conn, :upcoming_route_departures, route_time_list)
  end

  # Returns the last station on the commuter rail lines traveling through the given stop, or the empty string
  # if the stop doesn't serve commuter rail. Note that this assumes that all CR lines at a station have the
  # same terminal, which is currently true but could conceivably change in the future.
  @spec terminal_station(Stop.t) :: String.t
  defp terminal_station(stop) do
    stop.id
    |> Routes.Repo.by_stop(type: 2)
    |> do_terminal_station
  end

  # Filter out non-CR stations.
  defp do_terminal_station([]), do: ""
  defp do_terminal_station([route | _]) do
    terminal = route.id
    |> Stops.Repo.by_route(0)
    |> List.first
    terminal.id
  end

  @spec access_alerts([Alerts.Alert.t], Stop.t) :: [Alerts.Alert.t]
  def access_alerts(alerts, stop) do
    alerts
    |> Enum.filter(&(&1.effect_name == "Access Issue"))
    |> stop_alerts(stop)
  end

  @spec stop_alerts([Alerts.Alert.t], Stop.t) :: [Alerts.Alert.t]
  def stop_alerts(alerts, stop) do
    Alerts.Stop.match(alerts, stop.id)
  end

  @spec stop_schedule(String.t, DateTime.t) :: [Schedules.Schedule.t]
  defp stop_schedule(stop_id, date) do
    Schedules.Repo.schedule_for_stop(stop_id, date: date)
  end

  @spec stop_predictions(String.t) :: [Predictions.Prediction.t]
  defp stop_predictions(stop_id) do
    Predictions.Repo.all(stop: stop_id)
  end

  defp all_alerts(conn, _opts) do
    assign(conn, :all_alerts, Alerts.Repo.all(conn.assigns.date_time))
  end

  @spec get_stop_info(Route.gtfs_route_type) :: {DetailedStopGroup.t, [DetailedStopGroup.t]}
  defp get_stop_info(mode) do
    mode
    |> DetailedStopGroup.from_mode()
    |> separate_mattapan()
  end

  # Separates mattapan from stop_info list
  @spec separate_mattapan([DetailedStopGroup.t]) :: {DetailedStopGroup.t, [DetailedStopGroup.t]}
  defp separate_mattapan(stop_info) do
    case Enum.find(stop_info, fn {route, _stops} -> route.id == "Mattapan" end) do
      nil -> {nil, stop_info}
      mattapan -> {mattapan, List.delete(stop_info, mattapan)}
    end
  end
end
