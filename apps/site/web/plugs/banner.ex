defmodule Site.Plugs.Banner do
  @moduledoc """

  A module Plug to handle the banner at the top of every page.

  * If there's a banner alert, that should always be displayed with the alert styling.
  * Otherwise, display the beta announcment banner if necessary.
  """

  @behaviour Plug
  import Plug.Conn, only: [assign: 3]

  defmodule Options do
    @moduledoc """

    Default options for the Banner plug.

    banner_fn: a function which returns either an Alert.Banner or nil
    show_announcement_fn?: a function which takes the conn and returns a boolean indicating
    whether we should show the beta announcment

    """
    defstruct [
      banner_fn: &Alerts.Repo.banner/0,
      show_announcement_fn?: &BetaAnnouncement.show_announcement?/1
    ]

    @type t :: %__MODULE__{
      banner_fn: (() -> Alerts.Banner.t | nil),
      show_announcement_fn?: ((Plug.Conn.t) -> boolean)
    }
  end

  alias __MODULE__.Options

  def init(opts), do: struct!(Options, opts)

  def call(conn, opts) do
    if banner = opts.banner_fn.() do
      assign_alert_banner(conn, banner)
    else
      assign_beta_announcment(conn, opts)
    end
  end

  @spec assign_alert_banner(Plug.Conn.t, Alerts.Banner.t) :: Plug.Conn.t
  defp assign_alert_banner(conn, banner) do
    conn
    |> assign(:alert_banner, banner)
    |> assign(:banner_class, "alert-announcement-container")
    |> assign(:banner_template, "_alert_announcement.html")
  end

  @spec assign_beta_announcment(Plug.Conn.t, Options.t) :: Plug.Conn.t
  defp assign_beta_announcment(conn, opts) do
    if opts.show_announcement_fn?.(conn) do
      conn
      |> assign(:banner_template, "_beta_announcement.html")
    else
      conn
    end
  end
end
