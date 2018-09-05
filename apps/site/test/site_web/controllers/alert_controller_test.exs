defmodule SiteWeb.AlertControllerTest do
  use SiteWeb.ConnCase

  use Phoenix.Controller
  alias Alerts.Alert
  alias SiteWeb.PartialView.SvgIconWithCircle
  import SiteWeb.AlertController, only: [group_access_alerts: 1]

  test "renders commuter rail", %{conn: conn} do
    conn = get conn, alert_path(conn, :show, "commuter-rail")
    assert html_response(conn, 200) =~ "Commuter Rail"
  end

  describe "index/2" do
    test "index page is redirected to subway", %{conn: conn} do
      conn = get(conn, "/alerts")
      assert redirected_to(conn, 302) == "/alerts/subway"
    end
  end

  describe "show/2" do
    test "alerts are assigned for all modes", %{conn: conn} do
      for mode <- [:bus, "commuter-rail", :subway, :ferry] do
        conn = get(conn, alert_path(conn, :show, mode))
        assert conn.assigns.all_alerts
      end
    end

    test "alerts are assigned for the access tab", %{conn: conn} do
      conn = get(conn, alert_path(conn, :show, :access))
      assert conn.assigns.all_alerts
    end

    test "invalid mode does not assign alerts", %{conn: conn} do
      conn = get(conn, alert_path(conn, :show, :bicycle))
      refute conn.assigns[:all_alerts]
    end
  end

  describe "mode icons" do
    setup %{conn: conn} do
      {:ok, conn: conn, alerts: Enum.map([:bus, :subway, :commuter_rail, :ferry, :access], &create_alert/1)}
    end

    test "are shown on subway alerts", %{conn: conn, alerts: alerts} do
      response = render_alerts_page(conn, :subway, alerts)

      expected = %SvgIconWithCircle{icon: :red_line, aria_hidden?: true}
      |> SvgIconWithCircle.svg_icon_with_circle
      |> Phoenix.HTML.safe_to_string
      |> Kernel.<>(:red_line |> get_route |> Map.get(:name))

      assert response =~ expected
    end
    test "are not shown on non-subway alerts", %{conn: conn, alerts: alerts} do
      for mode <- [:bus, :commuter_rail, :access] do
        response = render_alerts_page(conn, mode, alerts)
        assert response =~ "alert-show-title alert-show-title-#{mode}"
        refute response =~ mode_icon_tag(mode)
      end
    end

    defp render_alerts_page(conn, mode, alerts) do
      conn
      |> put_view(SiteWeb.AlertView)
      |> render("show.html", id: mode, route_alerts: alerts, breadcrumbs: ["Alerts"], date: Util.now())
      |> html_response(200)
    end

    defp mode_icon_tag(mode) do
      %SvgIconWithCircle{icon: mode}
      |> SvgIconWithCircle.svg_icon_with_circle
      |> Phoenix.HTML.safe_to_string
      |> Kernel.<>(mode |> get_route |> Map.get(:name))
    end

    defp create_alert(mode) do
      mode
      |> get_route
      |> do_create_alert(mode)
    end

    defp get_route(:ferry), do: %Routes.Route{id: "Boat-F4", description: :ferry, name: "Charlestown Ferry", type: 4}
    defp get_route(:bus), do: %Routes.Route{id: "59", description: :local_bus, name: "59", type: 3}
    defp get_route(mode) when mode in [:subway, :access, :red_line], do: %Routes.Route{id: "Red", description: :rapid_transit,
                                                                                       name: "Red Line", type: 1}
    defp get_route(:commuter_rail), do: %Routes.Route{id: "CR-Fitchburg", description: :commuter_rail,
                                                      name: "Fitchburg Line", type: 2}

    defp do_create_alert(route, mode) do
      {route, [Alert.new(
        active_period: [{Util.now() |> Timex.shift(days: -2), nil}],
        informed_entity: [informed_entity(mode)],
        updated_at: Util.now() |> Timex.shift(days: -2),
        effect: effect(mode)
      )]}
    end

    defp informed_entity(mode) when mode in [:subway, :access] do
      %Alerts.InformedEntity{route: "Red", route_type: 1, direction_id: 1}
    end
    defp informed_entity(:commuter_rail) do
      %Alerts.InformedEntity{route: "CR-Fitchburg", route_type: 2, direction_id: 1}
    end
    defp informed_entity(:bus) do
      %Alerts.InformedEntity{route: "59", route_type: 3, direction_id: nil, stop: "81448", trip: nil}
    end
    defp informed_entity(:ferry) do
      %Alerts.InformedEntity{route: "Boat-F4", route_type: 4, direction_id: 1, stop: "Boat-Charlestown"}
    end

    defp effect(:commuter_rail), do: :track_change
    defp effect(:access), do: :access_issue
    defp effect(_mode), do: :delay
  end

  describe "group_access_alerts/1" do
    test "given a list of alerts, groups the access alerts by type" do
      alerts = [
        Alert.new(effect: :escalator_closure, header: "Escalator Alert"),
        Alert.new(effect: :elevator_closure, header: "Elevator Alert"),
        Alert.new(effect: :access_issue, header: "Access Alert")
      ]

      assert group_access_alerts(alerts) == %{
        %Routes.Route{id: "Escalator", name: "Escalator"} => [Enum.at(alerts, 0)],
        %Routes.Route{id: "Elevator", name: "Elevator"} => [Enum.at(alerts, 1)],
        %Routes.Route{id: "Other", name: "Other"} => [Enum.at(alerts, 2)]
      }
    end

    test "keeps alerts in order within a a type" do
      alerts = [
        Alert.new(effect: :escalator_closure, header: "Escalator Alert 1"),
        Alert.new(effect: :escalator_closure, header: "Escalator Alert 2"),
     ]

      assert group_access_alerts(alerts) == %{
        %Routes.Route{id: "Elevator", name: "Elevator"} => [],
        %Routes.Route{id: "Escalator", name: "Escalator"} => alerts,
        %Routes.Route{id: "Other", name: "Other"} => [],
      }
    end

    test "ignores non access Issue, elevator or escalator  alerts" do
      assert group_access_alerts([Alert.new()]) == %{
        %Routes.Route{id: "Elevator", name: "Elevator"} => [],
        %Routes.Route{id: "Escalator", name: "Escalator"} => [],
        %Routes.Route{id: "Other", name: "Other"} => [],
      }
    end
  end

  describe "mTicket detection" do
    test "mTicket matched", %{conn: conn} do
      response = conn
      |> put_req_header("user-agent", "Java/1.8.0_91")
      |> get(alert_path(conn, :show, "commuter-rail"))
      |> html_response(200)

      assert response =~ "mticket-notice"
      assert response =~ "access alerts:"
      assert response =~ "/alerts/commuter-rail"
    end

    test "mTicket not matched", %{conn: conn} do
      response = conn
      |> get(alert_path(conn, :show, "commuter-rail"))
      |> html_response(200)

      refute response =~ "mticket-notice"
    end
  end
end
