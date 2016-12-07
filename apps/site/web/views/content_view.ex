defmodule Site.ContentView do
  use Site.Web, :view

  @doc "Returns the srcset attribute for maps at a given set of sizes."
  @spec scaled_map_srcset([{number, number}], String.t) :: String.t
  def scaled_map_srcset(sizes, address) do
    sizes
    |> GoogleMaps.scale
    |> Enum.map(fn {width, height, scale} ->
      {"#{width * scale}", map_url(address, width, height, scale)}
    end)
    |> Picture.srcset
  end

  @doc "URL for the embedded Google map image for an address."
  @spec map_url(String.t, non_neg_integer, non_neg_integer, non_neg_integer) :: String.t
  def map_url(address, width, height, scale) do
    %{
      size: "#{width}x#{height}",
      channel: "beta_mbta_content",
      zoom: 16,
      scale: scale,
      markers: address
    }
    |> URI.encode_query
    |> (fn query -> "/maps/api/staticmap?#{query}" end).()
    |> GoogleMaps.signed_url
  end

  @doc "Nicely renders the duration of an event, given two DateTimes."
  @spec event_duration(NaiveDateTime.t | DateTime.t, NaiveDateTime.t | DateTime.t | nil) :: String.t
  def event_duration(start_time, end_time)
  def event_duration(start_time, nil) do
    start_time
    |> maybe_shift_timezone
    |> do_event_duration(nil)
  end
  def event_duration(start_time, end_time) do
    start_time
    |> maybe_shift_timezone
    |> do_event_duration(maybe_shift_timezone(end_time))
  end

  defp maybe_shift_timezone(%NaiveDateTime{} = time) do
    time
  end
  defp maybe_shift_timezone(%DateTime{} = time) do
    Util.to_local_time(time)
  end

  defp do_event_duration(start_time, nil) do
    "#{format_date(start_time)} #{format_time(start_time)}"
  end
  defp do_event_duration(
    %{year: year, month: month, day: day} = start_time,
    %{year: year, month: month, day: day} = end_time) do
    "#{format_date(start_time)} #{format_time(start_time)} until #{format_time(end_time)}"
  end
  defp do_event_duration(start_time, end_time) do
    "#{format_date(start_time)} #{format_time(start_time)} until #{format_date(end_time)} #{format_time(end_time)}"
  end

  defp ordinal_number(number)
  defp ordinal_number(1), do: "1st"
  defp ordinal_number(2), do: "2nd"
  defp ordinal_number(3), do: "3rd"
  defp ordinal_number(number) when is_number(number), do: "#{number}th"

  defp format_date(date) do
    Timex.format!(date, "{WDfull}, {Mfull} #{date.day |> ordinal_number}")
  end

  defp format_time(time) do
    Timex.format!(time, "{h12}:{m} {AM}")
  end
end
