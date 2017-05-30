defmodule Stops.RouteStopsTest do
  use ExUnit.Case
  alias Stops.{RouteStops}

  @red %Routes.Route{id: "Red", type: 1}

  describe "by_direction/2 returns a list of stops in one direction in the correct order" do
    test "for Red Line, direction: 0" do
      stops = Stops.Repo.by_route("Red", 0)
      shapes = Routes.Repo.get_shapes("Red", 0)
      stops = RouteStops.by_direction(stops, shapes, @red, 0)
      [core, braintree, ashmont] = stops
      assert %Stops.RouteStops{branch: nil, stops: unbranched_stops} = core
      assert %Stops.RouteStops{branch: "Braintree", stops: braintree_stops} = braintree
      assert %Stops.RouteStops{branch: "Ashmont", stops: ashmont_stops} = ashmont

      assert unbranched_stops |> Enum.map(& &1.name) == ["Alewife", "Davis", "Porter", "Harvard", "Central",
        "Kendall/MIT", "Charles/MGH", "Park Street", "Downtown Crossing", "South Station", "Broadway", "Andrew", "JFK/Umass"]

      [alewife | _] = unbranched_stops
      assert alewife.is_terminus? == true
      assert alewife.zone == nil
      assert alewife.branch == nil
      assert alewife.stop_features == [:bus, :access, :parking_lot]
      assert alewife.stop_number == 0

      jfk = List.last(unbranched_stops)
      assert jfk.name == "JFK/Umass"
      assert jfk.branch == nil
      assert jfk.stop_features == [:commuter_rail, :bus, :access]
      assert jfk.is_terminus? == false
      assert jfk.stop_number == 12

      assert [savin|_] = ashmont_stops
      assert savin.name == "Savin Hill"
      assert savin.branch == "Ashmont"
      assert savin.stop_features == [:access, :parking_lot]
      assert savin.is_terminus? == false
      assert savin.stop_number == 13

      ashmont = List.last(ashmont_stops)
      assert ashmont.name == "Ashmont"
      assert ashmont.branch == "Ashmont"
      assert ashmont.stop_features == [:mattapan_trolley, :bus, :access]
      assert ashmont.is_terminus? == true
      assert ashmont.stop_number == 16

      [north_quincy|_] = braintree_stops
      assert north_quincy.name == "North Quincy"
      assert north_quincy.branch == "Braintree"
      assert north_quincy.stop_features == [:bus, :access, :parking_lot]
      assert north_quincy.is_terminus? == false
      assert north_quincy.stop_number == 13

      braintree = List.last(braintree_stops)
      assert braintree.name == "Braintree"
      assert braintree.branch == "Braintree"
      assert braintree.stop_features == [:commuter_rail, :bus, :access, :parking_lot]
      assert braintree.is_terminus? == true
      assert braintree.stop_number == 17
    end

    test "for Red Line, direction: 1" do
      stops = Stops.Repo.by_route("Red", 1)
      shapes = Routes.Repo.get_shapes("Red", 1)
      stops = RouteStops.by_direction(stops, shapes, @red, 1)

      [ashmont, braintree, core] = stops
      assert %Stops.RouteStops{branch: "Ashmont", stops: ashmont_stops} = ashmont
      assert %Stops.RouteStops{branch: "Braintree", stops: braintree_stops} = braintree
      assert %Stops.RouteStops{branch: nil, stops: _unbranched_stops} = core

      [ashmont|_] = ashmont_stops
      assert ashmont.name == "Ashmont"
      assert ashmont.branch == "Ashmont"
      assert ashmont.is_terminus? == true
      assert ashmont.stop_number == 0

      savin = List.last(ashmont_stops)
      assert savin.name == "Savin Hill"
      assert savin.branch == "Ashmont"
      assert savin.is_terminus? == false
      assert savin.stop_number == 3

      [braintree|_] = braintree_stops
      assert braintree.name == "Braintree"
      assert braintree.branch == "Braintree"
      assert braintree.stop_features == [:commuter_rail, :bus, :access, :parking_lot]
      assert braintree.is_terminus? == true
      assert braintree.stop_number == 0

      n_quincy = List.last(braintree_stops)
      assert n_quincy.name == "North Quincy"
      assert n_quincy.branch == "Braintree"
      assert n_quincy.is_terminus? == false
      assert n_quincy.stop_number == 4
    end

    test "works for green E line" do
      route = %Routes.Route{id: "Green-E", type: 0}
      shapes = Routes.Repo.get_shapes("Green-E", 0)
      stops = Stops.Repo.by_route("Green-E", 0)
      stops = RouteStops.by_direction(stops, shapes, route, 0)

      assert [%Stops.RouteStops{branch: "Heath Street", stops: [%Stops.RouteStop{id: "place-lech", is_terminus?: true}|_]}] = stops
    end

    test "works for green non-E line" do
      route = %Routes.Route{id: "Green-B", type: 0}
      shapes = Routes.Repo.get_shapes("Green-B", 0)
      stops = Stops.Repo.by_route("Green-B", 0)
      stops = RouteStops.by_direction(stops, shapes, route, 0)

      assert [%Stops.RouteStops{branch: "Boston College", stops: [%Stops.RouteStop{id: "place-pktrm", is_terminus?: true}|_] = b_stops}] = stops
      assert %Stops.RouteStop{id: "place-lake", is_terminus?: true} = List.last(b_stops)
    end


    test "works for Kingston line (outbound)" do
      route = %Routes.Route{id: "CR-Kingston", type: 2}
      shapes = Routes.Repo.get_shapes("CR-Kingston", 0)
      stops = Stops.Repo.by_route("CR-Kingston", 0)
      route_stops = RouteStops.by_direction(stops, shapes, route, 0)

      [core, plymouth, kingston] = route_stops
      assert %Stops.RouteStops{branch: nil, stops: [%Stops.RouteStop{id: "place-sstat"} | _unbranched_stops]} = core
      assert %Stops.RouteStops{branch: "Plymouth", stops: [%Stops.RouteStop{id: "Plymouth"}]} = plymouth
      assert %Stops.RouteStops{branch: "Kingston", stops: [%Stops.RouteStop{id: "Kingston"}]} = kingston
    end

    test "works for Providence line (inbound)" do
      route = %Routes.Route{id: "CR-Providence", type: 2}
      shapes = Routes.Repo.get_shapes("CR-Providence", 1)
      stops = Stops.Repo.by_route("CR-Providence", 1)
      route_stops = RouteStops.by_direction(stops, shapes, route, 1)

      [wickford, stoughton, core] = route_stops
      assert %Stops.RouteStops{branch: "Wickford Junction", stops: [%Stops.RouteStop{id: "Wickford Junction"} | _]} = wickford
      assert %Stops.RouteStops{branch: "Stoughton", stops: [%Stops.RouteStop{id: "Stoughton"} | _]} = stoughton
      assert %Stops.RouteStops{branch: nil, stops: [_, _, _, _, _, %Stops.RouteStop{id: "place-sstat"}]} = core
    end

    test "works for bus routes" do
      stops = Stops.Repo.by_route("1", 0)
      shapes = Routes.Repo.get_shapes("1", 0)
      route = %Routes.Route{id: "1", type: 3}
      [%Stops.RouteStops{branch: "Harvard", stops: outbound}] = RouteStops.by_direction(stops, shapes, route, 0)
      assert is_list(outbound)
      assert Enum.all?(outbound, & &1.branch == "Harvard")
      assert outbound |> List.first() |> Map.get(:is_terminus?) == true
      assert outbound |> Enum.slice(1..-2) |> Enum.all?(& &1.is_terminus? == false)

      stops = Stops.Repo.by_route("1", 1)
      shapes = Routes.Repo.get_shapes("1", 1)
      route = %Routes.Route{id: "1", type: 3}

      [%Stops.RouteStops{branch: "Dudley", stops: inbound}] = RouteStops.by_direction(stops, shapes, route, 1)
      assert Enum.all?(inbound, & &1.branch == "Dudley")
      assert inbound |> List.first() |> Map.get(:is_terminus?) == true
    end

    test "works for ferry routes" do
      stops = Stops.Repo.by_route("Boat-F4", 0)
      shapes = Routes.Repo.get_shapes("Boat-F4", 0)
      route = %Routes.Route{id: "Boat-F4", type: 4}
      [%Stops.RouteStops{branch: "Boat-Charlestown", stops: stops}] = RouteStops.by_direction(stops, shapes, route, 0)

      assert Enum.all?(stops, & &1.__struct__ == Stops.RouteStop)
    end
  end
end
