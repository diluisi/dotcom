defmodule SiteWeb.FareControllerTest do
  use SiteWeb.ConnCase
  import SiteWeb.FareController
  alias Fares.Fare
  alias SiteWeb.FareController.Filter

  describe "show" do
    test "renders commuter rail", %{conn: conn} do
      conn =
        get(
          conn,
          fare_path(conn, :show, "commuter-rail", origin: "place-sstat", destination: "Readville")
        )

      assert html_response(conn, 200) =~ "Commuter Rail"
    end

    test "renders ferry", %{conn: conn} do
      conn =
        get(conn, fare_path(conn, :show, :ferry, origin: "Boat-Long", destination: "Boat-Logan"))

      response = html_response(conn, 200)
      assert response =~ "Ferry"
      assert response =~ "Valid between"
      assert response =~ "Long Wharf"
      assert response =~ "Logan"
    end

    test "does not render georges island ferry due to summer-only service", %{conn: conn} do
      conn =
        get(
          conn,
          fare_path(conn, :show, :ferry, origin: "Boat-George", destination: "Boat-Logan")
        )

      response = html_response(conn, 200)

      refute response =~ "Georges Island Fare"
      refute response =~ "Child under 3"
      refute response =~ "Family 4-pack"
    end

    test "renders ferry when no destinations", %{conn: conn} do
      conn = get(conn, fare_path(conn, :show, :ferry))
      response = html_response(conn, 200)
      assert response =~ "Find Your Fare"
    end

    test "renders a page about retail sale locations", %{conn: conn} do
      conn = get(conn, fare_path(conn, :show, "retail-sales-locations"))
      assert html_response(conn, 200) =~ "Retail Sales Locations"
    end

    test "404s on nonexistant mode", %{conn: conn} do
      conn = get(conn, fare_path(conn, :show, :doesnotexist))
      assert html_response(conn, 404) =~ "Your stop cannot be found."
    end

    test "sets a custom meta description", %{conn: conn} do
      conn =
        get(
          conn,
          fare_path(conn, :show, "commuter-rail", origin: "place-sstat", destination: "Readville")
        )

      assert conn.assigns.meta_description
    end
  end

  describe "fare_sales_locations/2" do
    test "calculates nearest retail_sales_locations" do
      nearby_fn = fn position ->
        [{%{latitude: position.latitude, longitude: position.longitude}, 10.0}]
      end

      locations = fare_sales_locations(%{latitude: 42.0, longitude: -71.0}, nearby_fn)
      assert locations == [{%{latitude: 42.0, longitude: -71.0}, 10.0}]
    end

    test "when there is no search position, is an empty list of nearby locations" do
      nearby_fn = fn position ->
        [{%{latitude: position.latitude, longitude: position.longitude}, 10.0}]
      end

      locations = fare_sales_locations(%{}, nearby_fn)
      assert locations == []
    end
  end

  describe "calculate_position/2" do
    test "it calculates search position and address" do
      params = %{"location" => %{"address" => "42.0, -71.0"}}

      geocode_fn = fn _address ->
        {:ok,
         [%GoogleMaps.Geocode.Address{formatted: "address", latitude: 42.0, longitude: -70.1}]}
      end

      {position, formatted} = calculate_position(params, geocode_fn)

      assert formatted == "address"
      assert %{latitude: 42.0, longitude: -70.1} = position
    end

    test "does not geocode if latitude/longitude params exist" do
      params = %{"latitude" => "42.0", "longitude" => "-71.0"}

      geocode_fn = fn _ ->
        send(self(), :geocode_called)
        {:error, :no_results}
      end

      {position, formatted} = calculate_position(params, geocode_fn)
      refute_received :geocode_called
      assert formatted == "42.0,-71.0"
      assert %{latitude: 42.0, longitude: -71.0} = position
    end

    test "handles bad lat/lng values" do
      params = %{"latitude" => "foo", "longitude" => "bar"}

      geocode_fn = fn _address ->
        send(self(), :geocode_called)

        {:ok,
         [%GoogleMaps.Geocode.Address{formatted: "address", latitude: 42.0, longitude: -70.1}]}
      end

      {position, formatted} = calculate_position(params, geocode_fn)
      refute_received :geocode_called
      assert position == %{}
      assert formatted == ""
    end

    test "when there is no location map there is no position" do
      params = %{}
      geocode_fn = fn _address -> %{formatted: "address", latitude: 42.0, longitude: -71.0} end
      {position, formatted} = calculate_position(params, geocode_fn)
      assert formatted == ""
      assert position == %{}
    end
  end

  describe "current_pass/1" do
    test "is the current month when the date given is prior to the 15th" do
      {:ok, date} = Timex.parse("2016-12-01T12:12:12-05:00", "{ISO:Extended}")

      assert current_pass(date) == "December 2016"
    end

    test "is the next month when the date given is the 15th or later" do
      {:ok, date} = Timex.parse("2016-12-15T12:12:12-05:00", "{ISO:Extended}")

      assert current_pass(date) == "January 2017"
    end

    test "uses the date passed in if there is one", %{conn: conn} do
      conn =
        get(
          conn,
          fare_path(conn, :show, "retail-sales-locations", date_time: "2013-01-01T12:12:12-05:00")
        )

      assert html_response(conn, 200) =~ "January 2013"
    end
  end

  describe "filter_reduced/2" do
    @fares [
      %Fare{name: {:zone, "6"}, reduced: nil},
      %Fare{name: {:zone, "5"}, reduced: nil},
      %Fare{name: {:zone, "6"}, reduced: :student}
    ]

    test "filters out non-standard fares" do
      expected_fares = [
        %Fare{name: {:zone, "6"}, reduced: nil},
        %Fare{name: {:zone, "5"}, reduced: nil}
      ]

      assert filter_reduced(@fares, nil) == expected_fares
    end

    test "filters out non-student fares" do
      expected_fares = [%Fare{name: {:zone, "6"}, reduced: :student}]
      assert filter_reduced(@fares, :student) == expected_fares
    end
  end

  describe "selected_filter" do
    @filters [
      %Filter{id: "1"},
      %Filter{id: "2"}
    ]

    test "defaults to returning the first filter" do
      assert selected_filter(@filters, nil) == List.first(@filters)
      assert selected_filter(@filters, "unknown") == List.first(@filters)
    end

    test "returns the filter based on the id" do
      assert selected_filter(@filters, "1") == List.first(@filters)
      assert selected_filter(@filters, "2") == List.last(@filters)
    end

    test "if there are no filters, return nil" do
      assert selected_filter([], "1") == nil
    end
  end
end
