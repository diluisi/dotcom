defmodule Site.TripPlanView do
  use Site.Web, :view
  require Routes.Route
  alias Site.TripPlan.{Query, ItineraryRow}
  alias Routes.Route

  @spec rendered_location_error(Plug.Conn.t, Query.t | nil, :from | :to) :: Phoenix.HTML.Safe.t
  def rendered_location_error(conn, query_or_nil, location_field)
  def rendered_location_error(_conn, nil, _location_field) do
    ""
  end
  def rendered_location_error(%Plug.Conn{} = conn, %Query{} = query, field) when field in [:from, :to] do
    case Map.get(query, field) do
      {:error, error} ->
        do_render_location_error(conn, field, error)
      _ ->
        ""
    end
  end

  @spec do_render_location_error(Plug.Conn.t, :from | :to, TripPlan.Geocode.error) :: Phoenix.HTML.Safe.t
  defp do_render_location_error(_conn, _field, :no_results) do
    "That address was not found. Please try a different address."
  end
  defp do_render_location_error(conn, field, {:multiple_results, results}) do
    render "_error_multiple_results.html", conn: conn, field: field, results: results
  end
  defp do_render_location_error(_conn, _field, :required) do
    "This field is required."
  end
  defp do_render_location_error(_conn, _field, :unknown) do
    "An unknown error occurred. Please try again, or try a different address."
  end

  @spec rendered_plan_error(term) :: Phoenix.HTML.Safe.t
  def rendered_plan_error(:prereq) do
    ""
  end
  def rendered_plan_error(no_plan) when no_plan in [:path_not_found, :too_close] do
    "We were unable to plan a trip between those locations."
  end
  def rendered_plan_error(:outside_bounds) do
    "We can only plan trips inside the MBTA transitshed."
  end
  def rendered_plan_error(:no_transit_times) do
    "We were unable to plan a trip at the time you selected."
  end
  def rendered_plan_error(:location_not_accessible) do
    "We were unable to plan an accessible trip between those locations."
  end
  def rendered_plan_error(_) do
    "We were unable to plan your trip. Please try again later."
  end

  def location_input_class(params, key) do
    if Query.fetch_lat_lng(params, Atom.to_string(key)) == :error do
      ""
    else
      "trip-plan-current-location"
    end
  end

  def mode_class(%ItineraryRow{route: %Route{} = route}) do
    route
    |> Site.Components.Icons.SvgIcon.get_icon_atom
    |> hyphenated_mode_string
  end
  def mode_class(_), do: "personal"

  @spec collapsible_row?(ItineraryRow.t) :: boolean()
  def collapsible_row?(%ItineraryRow{transit?: true, steps: steps}) when length(steps) > 5, do: true
  def collapsible_row?(_), do: false

  @spec stop_departure_display(ItineraryRow.t) :: {:render, String.t} | :blank
  def stop_departure_display(itinerary_row) do
    if itinerary_row.trip do
      :blank
    else
      {:render, format_schedule_time(itinerary_row.departure)}
    end
  end

  @spec render_stop_departure_display(:blank | {:render, String.t}) :: Phoenix.HTML.Safe.t
  def render_stop_departure_display(:blank), do: nil
  def render_stop_departure_display({:render, formatted_time}) do
    content_tag :div, formatted_time, class: "pull-right"
  end

  def bubble_params(%ItineraryRow{transit?: true} = itinerary_row, _row_idx) do
    base_params = %Site.StopBubble.Params{
      route_id: ItineraryRow.route_id(itinerary_row),
      route_type: ItineraryRow.route_type(itinerary_row),
      render_type: :stop,
      bubble_branch: ItineraryRow.route_name(itinerary_row)
    }

    params =
      itinerary_row.steps
      |> Enum.zip(Stream.concat(["stop dotted"], Stream.repeatedly(fn -> "stop"  end)))
      |> Enum.map(fn {step, class} ->
        {step, [%{base_params | class: class}]}
      end)

    [{:transfer, [%{base_params | class: "stop"}]} | params]
  end
  def bubble_params(%ItineraryRow{transit?: false} = itinerary_row, row_idx) do
    params =
      itinerary_row.steps
      |> Enum.map(fn step ->
        {step,
          [%Site.StopBubble.Params{
            render_type: :empty,
            class: "line dotted",
          }]}
      end)

    transfer_bubble_type =
      if row_idx == 0 do
        :terminus
      else
        :stop
      end

    [{:transfer,
          [%Site.StopBubble.Params{
            render_type: transfer_bubble_type,
            class: "#{transfer_bubble_type} dotted",
          }]}
     | params]
  end

  def render_steps(steps, mode_class) do
    for {step, bubbles} <- steps do
      render "_itinerary_row_step.html",
        step: step,
        mode_class: mode_class,
        bubble_params: bubbles
    end
  end
end
