defmodule Site.FareViewTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExCheck
  import Site.FareView
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]
  alias Fares.Fare

  property :description do
    for_all fare in elements(Fares.Repo.all()) do
      result = description(fare, %{})
      is_list(result) || is_binary(result)
    end
  end

  describe "fare_type_note/1" do
    test "returns fare note for students" do
      assert safe_to_string(fare_type_note(%Fare{mode: :commuter_rail, reduced: :student})) =~
        "Middle and high school students are eligible"
    end

    test "returns fare note for seniors" do
      assert safe_to_string(fare_type_note(%Fare{mode: :commuter_rail, reduced: :senior_disabled})) =~
        "People 65 or older and persons with disabilities"
    end

    test "returns fare note for bus and subway" do
      assert safe_to_string(fare_type_note(%Fare{mode: :bus, reduced: nil})) =~
        "To view prices and details for fare passes"
    end

    test "returns fare note for ferry" do
      assert safe_to_string(fare_type_note(%Fare{mode: :ferry, reduced: nil})) =~
      "You may pay for your Ferry fare on-board"
    end

    test "returns fare note for commuter rail" do
      assert safe_to_string(fare_type_note(%Fare{mode: :commuter_rail, reduced: nil})) =~
      "If you pay for a Round Trip "
    end
  end

  describe "vending_machine_stations/0" do
    test "generates a list of links to stations with fare vending machines" do
      content = vending_machine_stations()
      |> Enum.map(&raw/1)
      |> Enum.map(&safe_to_string/1)
      |> Enum.join("")

      assert content =~ "place-north"
      assert content =~ "place-sstat"
      assert content =~ "place-bbsta"
      assert content =~ "place-brntn"
      assert content =~ "place-forhl"
      assert content =~ "place-jfk"
      assert content =~ "Lynn"
      assert content =~ "place-mlmnl"
      assert content =~ "place-portr"
      assert content =~ "place-qnctr"
      assert content =~ "place-rugg"
      assert content =~ "Worcester"
    end
  end

  describe "charlie_card_stations/0" do
    test "generates a list of links to stations where a customer can buy a CharlieCard" do
      content = charlie_card_stations()
      |> Enum.map(&raw/1)
      |> Enum.map(&safe_to_string/1)
      |> Enum.join("")

      assert content =~ "place-alfcl"
      assert content =~ "place-armnl"
      assert content =~ "place-asmnl"
      assert content =~ "place-bbsta"
      assert content =~ "64000"
      assert content =~ "place-forhl"
      assert content =~ "place-harsq"
      assert content =~ "place-north"
      assert content =~ "place-ogmnl"
      assert content =~ "place-pktrm"
      assert content =~ "place-rugg"
    end
  end

  describe "reduced_image/1" do
    test "student descriptions given" do
      descriptions = reduced_image(:student)
                     |> Enum.map(&(elem(&1, 0)))
      assert descriptions == ["Back of Student CharlieCard", "Front of Student CharlieCard"]
    end
  end

  describe "destination_key_stops/2" do
    test "Unavailable key stops are filtered out" do
      key_stop1 = %Schedules.Stop{id: 1}
      key_stop2 = %Schedules.Stop{id: 2}
      dest_stop1 = %Schedules.Stop{id: 4}
      dest_stop2 = %Schedules.Stop{id: 5}
      dest_stop3 = %Schedules.Stop{id: 2}

      filtered = destination_key_stops([dest_stop1, dest_stop2, dest_stop3], [key_stop1, key_stop2])
      assert Enum.count(filtered) == 1
      assert List.first(filtered).id == 2
    end
  end

  describe "format_name/2" do
    test "uses ferry origin and destination" do
      origin = %Schedules.Stop{name: "North"}
      dest = %Schedules.Stop{name: "South"}
      tag = format_name(%Fare{mode: :ferry, duration: :week}, %{origin: origin, destination: dest})
      assert safe_to_string(tag) =~ "North"
      assert safe_to_string(tag) =~ "South"
    end
    test "Non ferry mode uses full name" do
      fare = %Fare{mode: :bus, duration: :week, name: "local_bus"}
      assert format_name(fare, %{}) == Fares.Format.full_name(fare)
    end
  end

  test "senior descriptions given" do
    descriptions = reduced_image(:senior_disabled)
                   |> Enum.map(&(elem(&1, 0)))
    assert descriptions == ["Transportation Access Pass", "Senior CharlieCard"]
  end

  test "No images given for non-reduced fare" do
    assert Enum.empty?(reduced_image(:adult))
  end

  describe "origin_destination_description/2" do
    test "for CR" do
      content = :commuter_rail |> origin_destination_description |> safe_to_string
      assert content =~ "Fares for the Commuter Rail"
      assert content =~ "www.mbta.com/uploadedimages/Fares_and_Passes_v2/Commuter_Rail/Commuter_Rail_List/Cr-Zones-Web.jpg"
    end

    test "for ferry" do
      content = :ferry |> origin_destination_description |> safe_to_string
      assert content =~ "Ferry fares depend on your origin and destination."
    end
  end

  describe "format_price/1" do
    test "given a list of fare filters, finds the fare that fits and formats its price" do
      assert format_price(mode: :subway, duration: :single_trip, media: [:charlie_card]) == "$2.25"
    end
  end
end
