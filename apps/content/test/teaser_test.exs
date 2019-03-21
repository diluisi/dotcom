defmodule Content.TeaserTest do
  use ExUnit.Case, async: true

  alias Content.CMS.Static
  alias Content.Field.Image
  alias Content.Teaser

  test "parses a teaser item into %Content.Teaser{}" do
    [raw | _] = Static.teaser_response()
    teaser = Teaser.from_api(raw)

    assert %Teaser{
             type: type,
             path: path,
             image: image,
             text: text,
             title: title,
             date: date,
             topic: topic,
             routes: routes
           } = teaser

    assert type == :project
    assert path == "/projects/green-line-d-track-and-signal-replacement"
    assert %Image{url: "http://" <> _, alt: "Tracks at Riverside"} = image
    assert text =~ "This project is part of"
    assert title == "Green Line D Track and Signal Replacement"
    assert topic == ""
    assert %Date{} = date
    assert [%{id: "Green-D"}] = routes
  end

  test "uses field_posted_on date for news entries" do
    raw =
      Static.teaser_response()
      |> List.first()
      |> Map.put("type", "news_entry")
      |> Map.put("changed", "2018-10-18")
      |> Map.put("posted", "2018-10-25")

    teaser = Teaser.from_api(raw)
    assert teaser.date.day == 25
  end

  test "sets date to null if date is invalid" do
    assert Static.teaser_response()
           |> List.last()
           |> Map.put("changed", "invalid")
           |> Teaser.from_api()
           |> Map.get(:date) == nil
  end

  test "uses updated field as date for projects" do
    assert Static.teaser_response()
           |> List.first()
           |> Teaser.from_api()
           |> Map.get(:date) == ~D[2018-10-10]
  end

  test "uses changed field as date for project when updated is blank" do
    assert Static.teaser_response()
           |> Enum.at(1)
           |> Teaser.from_api()
           |> Map.get(:date) == ~D[2018-10-04]
  end

  test "stores a list of all attached gtfs ids for later usage" do
    routes =
      Static.teaser_response()
      |> Enum.at(1)
      |> Teaser.from_api()
      |> Map.get(:routes)

    assert [%{id: "CR-Lowell"}, %{id: "CR-Providence"}] = routes
  end
end
