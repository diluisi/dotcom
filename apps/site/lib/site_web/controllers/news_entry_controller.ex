defmodule SiteWeb.NewsEntryController do
  use SiteWeb, :controller

  alias Content.NewsEntry
  alias Content.Repo
  alias Plug.Conn
  alias Site.Pagination
  alias SiteWeb.ControllerHelpers

  def index(conn, params) do
    page = current_page(params)
    items_per_page = 10
    zero_based_current_page = page - 1
    zero_based_next_page = page

    news_entry_teasers =
      Repo.teasers(
        type: "news_entry",
        items_per_page: items_per_page,
        offset: items_per_page * zero_based_current_page
      )

    upcoming_news_entry_teasers =
      Repo.teasers(
        type: "news_entry",
        items_per_page: items_per_page,
        offset: items_per_page * zero_based_next_page
      )

    conn
    |> assign(:breadcrumbs, index_breadcrumbs())
    |> assign(:news_entries, news_entry_teasers)
    |> assign(:upcoming_news_entries, upcoming_news_entry_teasers)
    |> assign(:page, page)
    |> render(:index)
  end

  def show(%Conn{} = conn, _params) do
    conn.request_path
    |> Repo.get_page(conn.query_params)
    |> do_show(conn)
  end

  defp do_show(%NewsEntry{} = news_entry, conn), do: show_news_entry(conn, news_entry)
  defp do_show({:error, {:redirect, status, opts}}, conn) do
    conn
    |> put_status(status)
    |> redirect(opts)
  end
  defp do_show(_404_or_mismatch, conn), do: render_404(conn)

  @spec show_news_entry(Conn.t, NewsEntry.t) :: Conn.t
  def show_news_entry(conn, %NewsEntry{posted_on: posted_on} = news_entry) do
    recent_news = Repo.recent_news(current_id: news_entry.id)

    conn
    |> ControllerHelpers.unavailable_after_one_year(posted_on)
    |> assign(:breadcrumbs, show_breadcrumbs(conn, news_entry))
    |> render(SiteWeb.NewsEntryView, "show.html", news_entry: news_entry, recent_news: recent_news)
  end

  defp current_page(params) do
    params
    |> Map.get("page")
    |> Pagination.current_page(1)
  end

  defp index_breadcrumbs do
    [Breadcrumb.build("News")]
  end

  defp show_breadcrumbs(conn, news_entry) do
    [
      Breadcrumb.build("News", news_entry_path(conn, :index)),
      Breadcrumb.build(news_entry.title)
    ]
  end

end
