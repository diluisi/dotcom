defmodule Stops.Api do
  @moduledoc """
  Wrapper around the remote stop information service.
  """
  alias Stops.StationInfoApi
  alias Stops.Stop

  @vending_machine_stations ["place-north", "place-sstat", "place-bbsta", "place-portr", "place-mlmnl",
                             "Lynn", "Worcester", "place-rugg", "place-forhl", "place-jfk", "place-qnctr",
                             "place-brntn"]
                             |> Map.new(&{&1, true})

  @charlie_card_stations [
    "place-alfcl",
    "place-armnl",
    "place-asmnl",
    "place-bbsta",
    "64000",
    "place-forhl",
    "place-harsq",
    "place-north",
    "place-ogmnl",
    "place-pktrm",
    "place-rugg"
  ]
  |> Map.new(&{&1, true})


  @spec all :: [Stop.t]
  def all do
    StationInfoApi.all
    |> map_json_api
  end

  @spec by_gtfs_id(String.t) :: Stop.t | nil
  def by_gtfs_id(gtfs_id) do
    station_info_task = Task.async fn -> gtfs_id
      |> StationInfoApi.by_gtfs_id
      |> map_json_api
      |> List.first
    end
    v3_task = Task.async fn ->
      gtfs_id
      |> V3Api.Stops.by_gtfs_id
    end
    merge_v3(Task.await(station_info_task), Task.await(v3_task))
  end

  defp map_json_api(%JsonApi{data: data}) do
    data
    |> Enum.map(&parse_stop/1)
  end

  defp parse_stop(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    id = attributes["gtfs_id"]
    %Stop{
      id: id,
      name: attributes["name"],
      address: attributes["address"],
      note: attributes["note"],
      accessibility: attributes["accessibility"],
      images: images(relationships["images"]),
      parking_lots: parking_lots(relationships),
      station?: true,
      has_fare_machine?: Map.get(@vending_machine_stations, id, false),
      has_charlie_card_vendor?: Map.get(@charlie_card_stations, id, false)
    }
  end

  defp parking_lots(%{"parking_lots" => lots}) do
    lots
    |> Enum.map(&parse_parking_lot/1)
  end
  defp parking_lots(%{"parkings" => []}) do
    []
  end
  defp parking_lots(%{"parkings" => [first|_] = parkings}) do
    # previous version of the Stop Info API
    manager = parse_manager(first.relationships["manager"])
    rate = first.attributes["rate"]
    note = first.attributes["note"]
    [
      %Stop.ParkingLot{
        name: "",
        average_availability: "",
        rate: rate,
        note: note,
        manager: manager,
        spots: parkings |> Enum.map(fn parking ->
          %Stop.Parking{
            type: parking.attributes["type"],
            spots: parking.attributes["spots"]} end)}
    ]
  end

  defp parse_parking_lot(%JsonApi.Item{attributes: attributes, relationships: relationships}) do
    %Stop.ParkingLot{
      name: attributes["name"],
      average_availability: attributes["average_availability"],
      rate: attributes["rate"],
      note: attributes["note"],
      manager: parse_manager(relationships["manager"]),
      spots: Enum.map(attributes["spots"], &parse_spot/1)
    }
  end

  defp parse_spot(%{"type" => type, "spots" => spots}) do
    %Stop.Parking{
      type: type,
      spots: spots
    }
  end

  defp parse_manager([%JsonApi.Item{attributes: attributes}]) do
    %Stop.Manager{
      name: attributes["name"],
      website: attributes["website"],
      phone: attributes["phone"],
      email: attributes["email"]
    }
  end
  defp parse_manager([]) do
    nil
  end

  defp images(nil), do: []
  defp images(items) do
    items
    |> Enum.map(fn image ->
      %Stop.Image{
        description: image.attributes["description"],
        url: image.attributes["url"],
        sort_order: image.attributes["sort_order"]}
    end)
  end

  defp merge_v3(station_info_stop, v3_stop_response)
  defp merge_v3(nil, %JsonApi{data: [stop | _]}) do
    accessibility = if stop.attributes["wheelchair_boarding"] == 1 do
      ["accessible"]
    else
      []
    end
    %Stop{
      id: stop.id,
      name: stop.attributes["name"],
      accessibility: accessibility,
      parking_lots: [],
      latitude: stop.attributes["latitude"],
      longitude: stop.attributes["longitude"]
    }
  end
  defp merge_v3(stop, %JsonApi{data: [%JsonApi.Item{attributes: %{"latitude" => latitude, "longitude" => longitude}}]}) do
    %Stop{stop | latitude: latitude, longitude: longitude}
  end
  defp merge_v3(stop, %{status_code: 404}) do
    # failed v3 response, just return the stop as-is
    stop
  end
end
