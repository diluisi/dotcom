defmodule Site.Mode.CommuterRailController do
  use Site.Mode.HubBehavior
  import Phoenix.HTML.Link, only: [link: 2]

  def route_type, do: 2

  def mode_name, do: "Commuter Rail"

  def map_image_url, do: "/images/commuter-rail-spider.jpg"

  def map_pdf_url do
    "http://www.mbta.com/uploadedfiles/Documents/Schedules_and_Maps/Commuter%20Rail%20Map.pdf"
  end

  def fare_description do
    [
      link_to_zone_fares(),
      " depend on the distance traveled (zones). Refer to the information below:"
    ]
  end

  def fares do
    Site.ViewHelpers.mode_summaries(:commuter_rail)
  end

  defp link_to_zone_fares do
    path = fare_path(Site.Endpoint, :show, "commuter_rail")
    link "Commuter Rail Fares", to: path
  end
end
