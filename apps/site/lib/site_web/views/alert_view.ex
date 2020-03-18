defmodule SiteWeb.AlertView do
  @moduledoc "Helper functions related to displaying Alerts on the web site."
  use SiteWeb, :view
  alias Alerts.{Alert, InformedEntity, InformedEntitySet}
  alias Routes.Route
  alias SiteWeb.PartialView.SvgIconWithCircle
  alias Stops.Stop
  import SiteWeb.ViewHelpers
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  import SiteWeb.PartialView.SvgIconWithCircle, only: [svg_icon_with_circle: 1]

  @doc """

  Used to render a group of alerts.

  """
  def group(opts) do
    stop? = Keyword.has_key?(opts, :stop)
    route = Keyword.get(opts, :stop) || Keyword.fetch!(opts, :route)
    show_empty? = Keyword.get(opts, :show_empty?, false)
    priority_filter = Keyword.get(opts, :priority_filter, :any)
    timeframe = Keyword.get(opts, :timeframe, nil)
    date_time = Keyword.get(opts, :date_time)

    alerts =
      opts
      |> Keyword.fetch!(:alerts)
      |> Enum.filter(&filter_by_priority(priority_filter, &1))

    case {alerts, show_empty?} do
      {[], true} ->
        content_tag(
          :div,
          no_alerts_message(route, stop?, timeframe),
          class: "callout"
        )

      {[], false} ->
        ""

      _ ->
        render(__MODULE__, "group.html", alerts: alerts, route: route, date_time: date_time)
    end
  end

  @spec no_alerts_message(map, boolean, atom) :: iolist
  def no_alerts_message(route, false, :current) do
    [
      "Service is running as expected",
      location_name(route, false),
      ". ",
      empty_message_for_timeframe(:current, "")
    ]
  end

  def no_alerts_message(route, false, :upcoming) do
    empty_message_for_timeframe(:upcoming, [" for the ", route.name])
  end

  def no_alerts_message(route, stop?, timeframe) do
    empty_message_for_timeframe(timeframe, location_name(route, stop?))
  end

  @spec location_name(map, boolean) :: iolist
  def location_name(route, true) do
    [" at ", route.name]
  end

  def location_name(route, false) do
    [" on the ", route.name]
  end

  @spec format_alerts_timeframe(atom | nil) :: String.t() | nil
  def format_alerts_timeframe(:upcoming) do
    "planned"
  end

  def format_alerts_timeframe(:all_timeframes) do
    ""
  end

  def format_alerts_timeframe(nil) do
    ""
  end

  def format_alerts_timeframe(timeframe) when is_atom(timeframe) do
    Atom.to_string(timeframe)
  end

  @spec empty_message_for_timeframe(atom | nil, String.t() | iolist | nil) :: iolist
  def empty_message_for_timeframe(:current, location),
    do: [
      "There are no ",
      format_alerts_timeframe(:current),
      " alerts",
      location,
      "."
    ]

  def empty_message_for_timeframe(nil, location),
    do: [
      "There are no alerts",
      location,
      " at this time."
    ]

  def empty_message_for_timeframe(timeframe, location),
    do: [
      "There are no ",
      format_alerts_timeframe(timeframe),
      " alerts",
      location,
      " at this time."
    ]

  @spec filter_by_priority(boolean, Alert.t()) :: boolean
  defp filter_by_priority(:any, _), do: true

  defp filter_by_priority(priority_filter, %{priority: priority})
       when priority_filter == priority,
       do: true

  defp filter_by_priority(_, _), do: false

  def effect_name(%{lifecycle: lifecycle} = alert)
      when lifecycle in [:new, :unknown] do
    Alert.human_effect(alert)
  end

  def effect_name(alert) do
    Alert.human_effect(alert)
  end

  defp alert_label_class(%Alert{} = alert) do
    ["u-small-caps", "c-alert-item__badge"]
    |> do_alert_label_class(alert)
    |> Enum.join(" ")
  end

  defp do_alert_label_class(class_list, %Alert{priority: priority})
       when priority == :system do
    ["c-alert-item__badge--system" | class_list]
  end

  defp do_alert_label_class(class_list, %Alert{lifecycle: lifecycle})
       when lifecycle in [:upcoming, :ongoing_upcoming] do
    ["c-alert-item__badge--upcoming" | class_list]
  end

  defp do_alert_label_class(class_list, _) do
    class_list
  end

  def alert_updated(%Alert{updated_at: updated_at}, relative_to) do
    alert_updated(updated_at, relative_to)
  end

  def alert_updated(updated_at, relative_to) do
    date =
      if Timex.equal?(relative_to, updated_at) do
        "Today at"
      else
        Timex.format!(updated_at, "{M}/{D}/{YYYY}")
      end

    time = format_schedule_time(updated_at)

    ["Updated: ", date, 32, time]
  end

  def format_alert_description(text) do
    import Phoenix.HTML

    text
    |> html_escape
    |> safe_to_string
    # an initial header
    |> String.replace(~r/^(.*:)\s/, "<strong>\\1</strong>\n")
    # all other start with a line break
    |> String.replace(~r/\n(.*:)\s/, "<br /><strong>\\1</strong>\n")
    |> String.replace(~r/\s*\n/s, "<br />")
    |> replace_urls_with_links
  end

  @url_regex ~r/(https?:\/\/)?([\da-z\.-]+)\.([a-z]{2,6})([\/\w\.-]*)*\/?/i

  @spec replace_urls_with_links(String.t()) :: Phoenix.HTML.safe()
  def replace_urls_with_links(text) do
    @url_regex
    |> Regex.replace(text, &create_url/1)
    |> raw
  end

  defp create_url(url) do
    # I could probably convince the Regex to match an internal period but not
    # one at the end, but this is clearer. -ps
    {url, suffix} =
      if String.ends_with?(url, ".") do
        String.split_at(url, -1)
      else
        {url, ""}
      end

    full_url = ensure_scheme(url)

    # remove [http:// | https:// | www.] from URL:
    stripped_url = String.replace(full_url, ~r/(https?:\/\/)?(www\.)?/i, "")

    # capitalize 'mbta' (special case):
    stripped_url =
      if String.contains?(stripped_url, "mbta") do
        String.replace(stripped_url, "mbta", "MBTA")
      else
        stripped_url
      end

    ~s(<a target="_blank" href="#{full_url}">#{stripped_url}</a>#{suffix})
  end

  defp ensure_scheme("http://" <> _ = url), do: url
  defp ensure_scheme("https://" <> _ = url), do: url
  defp ensure_scheme("mbta.com" <> _ = url), do: "https://" <> url
  defp ensure_scheme("MBTA.com" <> _ = url), do: "https://" <> url
  defp ensure_scheme(url), do: "http://" <> url

  @spec group_header_path(Route.t() | Stop.t()) :: String.t()
  def group_header_path(%Route{id: route_id}) do
    schedule_path(SiteWeb.Endpoint, :show, route_id)
  end

  def group_header_path(%Stop{id: stop_id}) do
    stop_path(SiteWeb.Endpoint, :show, stop_id)
  end

  @spec group_header_name(Route.t() | Stop.t()) :: Phoenix.HTML.Safe.t()
  defp group_header_name(%Route{long_name: long_name, name: name, type: 3}) do
    [name, content_tag(:span, long_name, class: "h3 m-alerts-header__long-name")]
  end

  defp group_header_name(%Route{name: name}) do
    [name]
  end

  defp group_header_name(%Stops.Stop{name: name}) do
    [name]
  end

  @spec show_mode_icon?(Route.t() | Stop.t()) :: boolean
  defp show_mode_icon?(%Stop{}), do: false

  defp show_mode_icon?(%Route{}), do: true

  @spec route_icon(Route.t()) :: Phoenix.HTML.Safe.t()
  def route_icon(%Route{type: 3, description: :rapid_transit}) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: :silver_line, aria_hidden?: true})
  end

  def route_icon(%Route{} = route) do
    svg_icon_with_circle(%SvgIconWithCircle{icon: Route.icon_atom(route), aria_hidden?: true})
  end

  @spec mode_buttons(atom) :: [Phoenix.HTML.Safe.t()]
  def mode_buttons(selected) do
    for mode <- [:subway, :bus, :commuter_rail, :ferry, :access] do
      link(
        [
          content_tag(
            :div,
            [
              content_tag(:div, type_icon(mode), class: "m-alerts__mode-icon"),
              content_tag(:div, type_name(mode), class: "m-alerts__mode-name")
            ],
            class: [
              "m-alerts__mode-button",
              if mode == selected do
                [" ", "m-alerts__mode-button--selected"]
              else
                []
              end
            ]
          )
        ],
        to: alert_path(SiteWeb.Endpoint, :show, mode),
        class: "m-alerts__mode-button-container"
      )
    end
  end

  @spec show_systemwide_alert?(map) :: boolean
  def show_systemwide_alert?(%{
        alert_banner: alert_banner,
        route_type: route_type
      }) do
    # Ensure route types are in a List
    route_types = List.flatten([route_type])

    Enum.any?(route_types, fn route_type ->
      InformedEntitySet.match?(
        alert_banner.informed_entity_set,
        %InformedEntity{route_type: route_type}
      )
    end)
  end

  def show_systemwide_alert?(_) do
    false
  end

  @spec type_name(atom) :: String.t()
  defp type_name(:commuter_rail), do: "Rail"
  defp type_name(mode), do: mode_name(mode)

  @spec type_icon(atom) :: Phoenix.HTML.Safe.t()
  defp type_icon(:access), do: svg("icon-accessible-default.svg")
  defp type_icon(mode), do: mode_icon(mode, :default)

  @spec alert_icon(Alert.icon_type()) :: Phoenix.HTML.Safe.t()
  defp alert_icon(:shuttle), do: svg("icon-shuttle-default.svg")
  defp alert_icon(:cancel), do: svg("icon-cancelled-default.svg")
  defp alert_icon(:snow), do: svg("icon-snow-default.svg")
  defp alert_icon(:alert), do: svg("icon-alerts-triangle.svg")
  defp alert_icon(:none), do: ""
end
