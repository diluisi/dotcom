defmodule SiteWeb.ScheduleV2Controller.Pdf do
  @moduledoc """
  For getting all the pdfs associated with a route from the CMS.

  The pdf action redirects to the first up-to-date pdf if one exists,
  or the first upcoming pdf if necessary.
  """

  use SiteWeb, :controller

  plug SiteWeb.ScheduleV2Controller.RoutePdfs

  def pdf(%Plug.Conn{assigns: %{route_pdfs: pdfs}} = conn, _params) do
    case pdfs do
      [] ->
        render_404(conn)
      [%Content.RoutePdf{path: path} | _] ->
        redirect(conn, external: static_url(SiteWeb.Endpoint, path))
     end
  end
end
