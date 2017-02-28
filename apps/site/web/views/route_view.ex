defmodule Site.RouteView do
  use Site.Web, :view

  @doc """
  Returns a row for a given stop with all featured icons
  """
  @spec route_row(Plug.Conn.t, [atom], Stops.Stop.t) :: Phoenix.HTML.Safe.t
  def route_row(conn, stop_features, %Stops.Stop{name: name, id: id}) do
    icons = Enum.map(stop_features, & svg_icon_with_circle(%SvgIconWithCircle{icon: &1}))
    content_tag :span do
      [link(name, to: stop_path(conn, :show, id)) | icons]
    end
  end
end
