defmodule FaresTest do
  use ExUnit.Case, async: true
  doctest Fares

  describe "calculate_commuter_rail/2" do
    test "when the origin is zone 6, finds the zone 6 fares" do
      assert Fares.calculate_commuter_rail("6", "1A") == {:zone, "6"}
    end

    test "given two stops, finds the interzone fares" do
      assert Fares.calculate_commuter_rail("3", "5") == {:interzone, "3"}
    end

    test "when the origin is zone 1a, finds the fare based on destination" do
      assert Fares.calculate_commuter_rail("1A", "4") == {:zone, "4"}
    end
  end

  describe "fare_for_stops/3" do
    # a subset of possible ferry stops
    @ferries ~w(Boat-Hingham Boat-Charlestown Boat-Logan Boat-Long-South)

    test "returns the name of the commuter rail fare given the origin and destination" do
      zone_1a = "place-north"
      zone_4 = "Ballardvale"
      zone_7 = "Haverhill"

      assert Fares.fare_for_stops(:commuter_rail, zone_1a, zone_4) == {:ok, {:zone, "4"}}
      assert Fares.fare_for_stops(:commuter_rail, zone_7, zone_1a) == {:ok, {:zone, "7"}}
      assert Fares.fare_for_stops(:commuter_rail, zone_4, zone_7) == {:ok, {:interzone, "4"}}
    end

    test "returns an error if the fare doesn't exist" do
      assert Fares.fare_for_stops(:commuter_rail, "place-north", "place-pktrm") == :error
    end

    test "returns the name of the ferry fare given the origin and destination" do
      for origin_id <- @ferries,
          destination_id <- @ferries do
        both = [origin_id, destination_id]
        has_logan? = "Boat-Logan" in both
        has_charlestown? = "Boat-Charlestown" in both
        has_long? = "Boat-Long" in both
        has_long_south? = "Boat-Long-South" in both

        expected_name =
          cond do
            has_logan? and has_charlestown? -> :ferry_cross_harbor
            has_long? and has_logan? -> :ferry_cross_harbor
            has_long_south? and has_charlestown? -> :ferry_inner_harbor
            has_logan? -> :commuter_ferry_logan
            true -> :commuter_ferry
          end

        assert Fares.fare_for_stops(:ferry, origin_id, destination_id) == {:ok, expected_name}
      end
    end
  end

  describe "silver line rapid transit routes" do
    test "silver_line_rapid_transit?/1 returns true if a route id is in @silver_line_rapid_transit" do
      for id <- Fares.silver_line_rapid_transit() do
        assert Fares.silver_line_rapid_transit?(id)
      end

      refute Fares.silver_line_rapid_transit?("751")
    end
  end

  describe "express routes" do
    test "inner_express?/1 returns true if a route id is in @inner_express_routes" do
      for id <- Fares.inner_express() do
        assert Fares.inner_express?(id)
      end

      for id <- Fares.outer_express() do
        refute Fares.inner_express?(id)
      end

      refute Fares.inner_express?("1")
    end

    test "outer_express?/1 returns true if a route id is in @outer_express_routes" do
      for id <- Fares.outer_express() do
        assert Fares.outer_express?(id)
      end

      for id <- Fares.inner_express() do
        refute Fares.outer_express?(id)
      end

      refute Fares.outer_express?("1")
    end
  end

  describe "silver line airport origin routes" do
    test "inbound routes originating at airport are properly identified" do
      airport_stops = ["17091", "27092", "17093", "17094", "17095"]

      for origin_id <- airport_stops do
        assert Fares.silver_line_airport_stop?("741", origin_id)
      end

      refute Fares.silver_line_airport_stop?("742", "17091")
    end

    test "origin_id can be nil" do
      refute Fares.silver_line_airport_stop?("741", nil)
    end
  end
end
