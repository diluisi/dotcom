defmodule Schedules.RepoTest do
  use ExUnit.Case
  use Timex
  import Schedules.Repo
  import Mock
  alias Schedules.Schedule

  describe "by_route_ids/2" do
    test "can take a route/direction/sequence/date" do
      response = by_route_ids(
        ["CR-Lowell"],
        date: Util.service_date,
        direction_id: 1,
        stop_sequences: "first")
      assert response != []
      assert %Schedule{} = List.first(response)
    end

    test "can take multiple route IDs" do
      response = by_route_ids(
        ["1", "9"],
        direction_id: 1,
        stop_sequences: :first)
      refute response == []
      assert Enum.any?(response, & &1.route.id == "1")
      assert Enum.any?(response, & &1.route.id == "9")
    end

    test "returns the parent station as the stop" do
      response = by_route_ids(
        ["Red"],
        date: Util.service_date,
        direction_id: 0,
        stop_sequences: ["first"])
      assert response != []
      assert %{id: "place-alfcl", name: "Alewife"} = List.first(response).stop
    end

    test "if we get an error from the API, returns an error tuple" do
      response = by_route_ids(
        ["CR-Lowell"],
        date: "1970-01-01",
        stop: "place-north"
      )
      assert {:error, _} = response
    end
  end

  describe "schedule_for_trip/2" do
    @trip_id "Lowell"
    |> schedule_for_stop(direction_id: 1)
    |> List.first
    |> Map.get(:trip)
    |> Map.get(:id)

    test "returns stops in order of their stop_sequence for a given trip" do
      # find a Lowell trip ID
      response = schedule_for_trip(@trip_id)
      assert response |> Enum.all?(fn schedule -> schedule.trip.id == @trip_id end)
      refute response == []
      assert List.first(response).stop.id == "Lowell"
      assert List.last(response).stop.id == "place-north"
    end

    test "returns different values for different dates" do
      today = Util.service_date
      tomorrow = Timex.shift(today, days: 1)
      assert schedule_for_trip(@trip_id) == schedule_for_trip(@trip_id, date: today)
      refute schedule_for_trip(@trip_id, date: today) == schedule_for_trip(@trip_id, date: tomorrow)
    end
  end

  describe "trip/1" do
    test "returns nil for an invalid trip ID" do
      assert trip("invalid ID") == nil
      assert trip("") == nil
    end

    test "returns a %Schedule.Trip{} for a given ID" do
      date = Timex.shift(Util.service_date, days: 1)
      schedules = by_route_ids(["1"], date: date, stop_sequences: :first, direction_id: 0)
      scheduled_trip = List.first(schedules).trip
      trip = trip(scheduled_trip.id)
      assert scheduled_trip == trip
      refute trip.shape_id == nil
    end
  end

  describe "origin_destination/3" do
    test "returns pairs of Schedule items" do
      today = Util.service_date |> Timex.format!("{ISOdate}")
      response = origin_destination("Anderson/ Woburn", "North Station",
        date: today, direction_id: 1)
      [{origin, dest}|_] = response

      assert origin.stop.id == "Anderson/ Woburn"
      assert dest.stop.id == "place-north"
      assert origin.trip.id == dest.trip.id
      assert origin.time < dest.time
    end

    test "does not require a direction id" do
      today = Util.service_date |> Timex.format!("{ISOdate}")
      no_direction_id = origin_destination("Anderson/ Woburn", "North Station",
        date: today)
      direction_id = origin_destination("Anderson/ Woburn", "North Station",
        date: today, direction_id: 1)

      assert no_direction_id == direction_id
    end

    test "does not return duplicate trips if a stop hits multiple stops with the same parent" do
      next_tuesday = "America/New_York"
      |> Timex.now()
      |> Timex.end_of_week(:wed)
      |> Timex.format!("{ISOdate}")
      # stops multiple times at ruggles
      response = origin_destination("place-rugg", "1237", route: "43", date: next_tuesday)
      trips = Enum.map(response, fn {origin, _} -> origin.trip.id end)
      assert trips == Enum.uniq(trips)
    end

    test "returns an error tuple if we get an error from the API" do
      # when the API is updated such that this is an error, we won't need to
      # mock this anymore. -ps
      with_mock V3Api.Schedules, [all: fn _ -> {:error, :tuple} end] do
        response = origin_destination(
          "Anderson/ Woburn",
          "North Station")

        assert {:error, _} = response
      end
    end
  end

  describe "end_of_rating/1" do
    test "returns the date if it comes back from the API" do
      error = %JsonApi.Error{
        code: "no_service",
        meta: %{
          "end_date" => "2017-01-01"
        }
      }
      assert ~D[2017-01-01] = end_of_rating(fn _ -> {:error, [error]} end)
    end

    test "returns nil if there are problems" do
      refute end_of_rating(fn _ -> %JsonApi{} end)
    end

    @tag :external
    test "returns a date (actual endpoint)" do
      assert %Date{} = end_of_rating()
    end
  end

  describe "hours_of_operation/1" do
    @tag :external
    test "returns an %HoursOfOperation{} struct for a valid route" do
      assert %Schedules.HoursOfOperation{} = hours_of_operation("47")
    end

    @tag :external
    test "returns an %HoursOfOperation{} struct for an invalid route" do
      assert %Schedules.HoursOfOperation{} = hours_of_operation("unknown route ID")
    end
  end

  describe "insert_trips_into_cache/1" do
    test "caches trips that were already fetched" do
      trip_id = "trip_with_data"
      data = [
        %JsonApi.Item{
          relationships: %{
            "trip" => [%JsonApi.Item{
            id: trip_id,
            attributes: %{
              "headsign" => "North Station",
              "name" => "300",
              "direction_id" => 1,
            }}]}}]
      insert_trips_into_cache(data)
      assert {:ok, %Schedules.Trip{id: ^trip_id}} = ConCache.get(Schedules.Repo, {:trip, trip_id})
    end

    test "caches trips that don't have the right data as nil" do
      # this can happen with Green Line trips. By caching them, we avoid an
      # extra trip to the server only to get a 404.
      trip_id = "trip_without_right_data"
      data = [
        %JsonApi.Item{
          relationships: %{
            "trip" => [%JsonApi.Item{id: trip_id}]}}
      ]
      insert_trips_into_cache(data)
      assert ConCache.get(Schedules.Repo, {:trip, trip_id}) == {:ok, nil}
    end
  end
end
