defmodule TripInfoTest do
  use ExUnit.Case, async: true
  import TripInfo

  alias Routes.Route
  alias Predictions.Prediction
  alias Schedules.{Schedule, Trip}
  alias Stops.Stop
  alias Vehicles.Vehicle

  @route %Route{id: "1", name: "1", type: 3}
  @trip %Trip{id: "trip_id"}
  @time_list [
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-01T00:00:00],
      trip: @trip,
      route: @route,
      stop: %Stop{id: "place-sstat", name: "South Station"}}},
    %PredictedSchedule{schedule: %Schedule{stop: %Stop{id: "skipped during collapse"}}},
    %PredictedSchedule{schedule: %Schedule{stop: %Stop{id: "skipped during collapse"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-02T00:00:00],
      trip: @trip,
      route: @route,
      stop: %Stop{id: "place-north", name: "North Station"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-02T12:00:00],
      trip: @trip,
      route: @route,
      stop: %Stop{id: "place-censq", name: "Central Square"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-02T18:00:00],
      trip: @trip,
      route: @route,
      stop: %Stop{id: "place-harsq", name: "Harvard Square"}}},
    %PredictedSchedule{schedule: %Schedule{
      time: ~N[2017-01-03T00:00:00],
      trip: @trip,
      route: @route,
      stop: %Stop{id: "place-pktrm", name: "Park Street"}}}]
  @info %TripInfo{
    route: @route,
    origin_id: "place-sstat",
    destination_id: "place-pktrm",
    duration: 60 * 24 * 2, # 2 day duration trip
    times: @time_list,
    stop_count: Enum.count(@time_list),
    base_fare: %Fares.Fare{additional_valid_modes: [],
                           cents: 170,
                           duration: :single_trip,
                           media: [:charlie_card],
                           mode: :bus,
                           name: :local_bus,
                           reduced: nil}

  }

  describe "from_list/1" do
    test "creates a TripInfo from a list of PredictedSchedules" do
      actual = from_list(@time_list)
      expected = @info
      assert actual == expected
    end

    test "creates a TripInfo with origin/destination even when they are passed in as nil" do
      actual = from_list(@time_list, origin_id: nil, destination_id: nil)
      expected = @info
      assert actual == expected
    end

    test "creates a TripInfo even when the first or last prediction time is nil" do
      schedule = %Schedule{time: nil, trip: @trip, route: @route, stop: %Stop{id: "place-sstat", name: "South Station"}}
      assert from_list([%PredictedSchedule{schedule: schedule}] ++ @time_list).duration == nil
      assert from_list(@time_list ++ [%PredictedSchedule{schedule: schedule}]).duration == nil
    end

    test "given an origin, limits the times to just those after origin" do
      actual = from_list(@time_list, origin_id: "place-north")
      first_predicted_schedule = List.first(actual.times)
      assert PredictedSchedule.stop(first_predicted_schedule).id == "place-north"
      assert actual.duration == 60 * 24 # 1 day trip
    end

    test "given an origin and destination, limits both sides" do
      actual = from_list(@time_list, origin_id: "place-north", destination_id: "place-censq")
      first = List.first(actual.times)
      last = List.last(actual.times)
      assert PredictedSchedule.stop(first).id == "place-north"
      assert PredictedSchedule.stop(last).id == "place-censq"
      assert actual.duration == 60 * 12 # 12 hour trip
    end

    test "given an origin, does not care if the destination is the same as the origin" do
      [first | rest] = @time_list
      last_stop = rest |> List.last |> PredictedSchedule.stop
      first = put_in first.schedule.stop, last_stop
      actual = from_list([first | rest], origin_id: last_stop.id, destination_id: nil)
      assert List.first(actual.times) == first
      assert List.last(actual.times) == List.last(@time_list)
    end

    test "given an origin/destination/vehicle, does not keep stop before the origin if the vehicle is there" do
      actual = from_list(@time_list, origin_id: "place-censq", destination_id: "place-harsq", vehicle: %Vehicle{stop_id: "place-north"})
      first = List.first(actual.times)
      last = List.last(actual.times)
      assert PredictedSchedule.stop(first).id == "place-censq"
      assert PredictedSchedule.stop(last).id == "place-harsq"
      assert actual.duration == 60 * 6 # 6 hour trip from censq to harsq
    end

    test "given an origin/destination/vehicle, does not keep stops before the origin if the vehicle is after the origin" do
      actual = from_list(@time_list, origin_id: "place-north", destination_id: "place-harsq", vehicle: %Vehicle{stop_id: "place-censq"})
      first = List.first(actual.times)
      last = List.last(actual.times)
      assert PredictedSchedule.stop(first).id == "place-north"
      assert PredictedSchedule.stop(last).id == "place-harsq"
      assert actual.duration == 60 * 18
    end

    test "display all stops for the trip" do
      actual = from_list(@time_list, origin_id: "place-north", collapse?: true)
      assert actual.times == Enum.drop_while(@time_list, & PredictedSchedule.stop(&1).id != "place-north")
    end

    test "if there are not enough times, returns an error" do
      actual = @time_list |> Enum.take(1) |> from_list
      assert {:error, _} = actual
    end

    test "vehicle stop name is set" do
      actual = from_list(@time_list, vehicle_stop_name: "Central Square")
      assert actual.vehicle_stop_name == "Central Square"
    end

    test "vehicle stop name is not set, vehicle does not match any times" do
      actual = from_list(@time_list)
      assert actual.vehicle_stop_name == nil
    end
  end

  describe "is_current_trip?/2" do
    test "returns false there is no TripInfo to compare to" do
      assert is_current_trip?(nil, "trip_id") == false
    end

    test "returns false when TripInfo times is an empty list" do
      assert is_current_trip?(%TripInfo{times: []}, "trip_id") == false
    end

    test "returns false when first trip in TripInfo times doesn't match provided id" do
      assert is_current_trip?(@info, "not_trip_id") == false
    end

    test "returns true when first trip in TripInfo times matches provided id" do
      assert is_current_trip?(@info, "trip_id") == true
    end
  end

  describe "full_status/1" do
    test "nil for bus routes" do
      actual = @info |> full_status
      expected = nil
      assert actual == expected
    end

    test "result for CR, uses the route name" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 2},
        vehicle: %Vehicles.Vehicle{status: :incoming},
        vehicle_stop_name: "Readville"
      }
      actual = trip_info |> full_status |> IO.iodata_to_binary
      expected = "Train is on the way to Readville."
      assert actual == expected
    end

    test "nil when there is no vehicle" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 2},
        vehicle_stop_name: "Readville"
      }
      actual = trip_info |> full_status
      expected = nil
      assert actual == expected
    end

    test "result for Subway, uses the route name" do
      trip_info = %TripInfo{
        route: %Routes.Route{type: 1},
        vehicle: %Vehicles.Vehicle{status: :stopped},
        vehicle_stop_name: "Forest Hills"
      }
      actual = trip_info |> full_status
      expected = ["Train", " has arrived at ", "Forest Hills", "."]
      assert actual == expected
    end
  end

  describe "should_display_trip_info?/2" do
    test "Non subway will show trip info" do
      commuter_info = %TripInfo{route: %Routes.Route{type: 4}}
      assert should_display_trip_info?(commuter_info)
    end

    test "Subway will show trip info if predictions are given" do
      subway_info = %TripInfo{times: [%PredictedSchedule{prediction: %Prediction{time: Util.now()}}],
                              route: %Routes.Route{type: 1}}
      assert should_display_trip_info?(subway_info)
    end

    test "Will not show trip info if there is no trip info" do
      refute should_display_trip_info?(nil)
    end
  end
end
