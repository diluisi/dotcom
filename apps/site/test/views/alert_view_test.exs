defmodule Site.AlertViewTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import Phoenix.HTML, only: [safe_to_string: 1]
  import Site.AlertView

  @stop %Schedules.Stop{id: "stop_id"}
  @trip %Schedules.Trip{id: "trip_id"}
  @route %Routes.Route{type: 2, id: "route_id", name: "Name"}
  @schedule %Schedules.Schedule{stop: @stop, trip: @trip, route: @route}

  describe "alert_effects/1" do
    test "returns one alert for one effect" do
      delay_alert = %Alerts.Alert{effect_name: "Delay", lifecycle: "Upcoming"}

      expected = {"Delay (Upcoming)", ""}
      actual = alert_effects([delay_alert], 0)

      assert expected == actual
    end

    test "returns a count with multiple alerts" do
      alerts = [
        %Alerts.Alert{effect_name: "Suspension", lifecycle: "New"},
        %Alerts.Alert{effect_name: "Delay"},
        %Alerts.Alert{effect_name: "Cancellation"}
      ]

      expected = {"Suspension", "+2 more"}
      actual = alert_effects(alerts, 0)

      assert expected == actual
    end

    test "returns text when there are no current alerts" do
     assert alert_effects([], 0) == "There are no alerts for today."
     assert alert_effects([], 1) == "There are no alerts for today; 1 upcoming alert."
     assert alert_effects([], 2) == "There are no alerts for today; 2 upcoming alerts."
    end
  end

  test "alert_updated/1 returns the relative offset based on our timezone" do
    now = ~N[2016-10-05T01:02:03]
    date = ~D[2016-10-05]
    one_hour = Timex.shift(now, hours: -1)
    alert = %Alerts.Alert{updated_at: one_hour}

    assert alert_updated(alert, date) == "Last Updated: Today at 12:02 AM"
  end

  describe "format_alert_description/1" do
    test "escapes existing HTML" do
      expected = {:safe, "&lt;br&gt;"}
      actual = format_alert_description("<br>")

      assert expected == actual
    end

    test "replaces newlines with breaks" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\nthere")

      assert expected == actual
    end

    test "combines multiple newlines" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\n\n\nthere")

      assert expected == actual
    end

    test "combines multiple Windows newlines" do
      expected = {:safe, "hi<br />there"}
      actual = format_alert_description("hi\r\n\r\nthere")

      assert expected == actual
    end

    test "<strong>ifies a header" do
      expected = {:safe, "hi<hr><strong>Header:</strong><br />7:30"}
      actual = format_alert_description("hi\nHeader:\n7:30")

      assert expected == actual
    end

    test "<strong>ifies a starting long header" do
      expected = {:safe, "<strong>Long Header:</strong><br />7:30"}
      actual = format_alert_description("Long Header:\n7:30")

      assert expected == actual
    end
  end

  describe "modal.html" do
    test "text for no current alerts and 1 upcoming alert" do
      response = Site.AlertView.render("modal.html", alerts: [], upcoming_alert_count: 1, route: @route)
      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
      assert text =~ "However, there is 1 upcoming alert."
    end

    test "text for no current alerts and 2 upcoming alerts" do
      response = Site.AlertView.render("modal.html", alerts: [], upcoming_alert_count: 2, route: @route)
      text = safe_to_string(response)
      assert text =~ "There are currently no service alerts affecting the #{@route.name} today."
      assert text =~ "However, there are 2 upcoming alerts."
    end
  end
end
