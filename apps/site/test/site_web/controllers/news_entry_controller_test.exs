defmodule SiteWeb.NewsEntryControllerTest do
  use SiteWeb.ConnCase, async: true
  import Site.PageHelpers, only: [breadcrumbs_include?: 2]

  describe "GET index" do
    test "renders a list of news entries", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :index)

      body = html_response(conn, 200)
      assert body =~ "News"
      assert breadcrumbs_include?(body, "News")
    end

    test "supports pagination", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :index, page: 2)

      body = html_response(conn, 200)
      assert body =~ "Previous"
      assert body =~ news_entry_path(conn, :index, page: 1)
      assert body =~ "Next"
      assert body =~ news_entry_path(conn, :index, page: 3)
    end
  end

  describe "GET show" do
    test "renders and does not rewrite an unaliased news entry response", %{conn: conn} do
      news_entry = news_entry_factory(0, path_alias: nil)
      assert news_entry.title == {:safe, "New Early Morning Bus Routes Begin April 1"}
      path = news_entry_path(conn, :show, news_entry)
      assert path == "/node/3519"

      conn = get conn, path

      assert html_response(conn, 200) =~ "New Early Morning Bus Routes Begin April 1"
    end

    test "disambiguation: renders a news entry whose alias pattern is /news/:title instead of /news/:date/:title", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "incorrect-pattern")
      assert html_response(conn, 200) =~ "Weekend Bus Shuttle Service Effective April 7"
    end

    test "renders a news entry which has a path_alias", %{conn: conn} do
      news_entry = news_entry_factory(1)

      assert news_entry.path_alias == "/news/date/title"

      news_entry_title = Phoenix.HTML.safe_to_string(news_entry.title)
      conn = get conn, news_entry_path(conn, :show, news_entry)

      {:safe, rewritten_news_body} = Site.ContentRewriter.rewrite(news_entry.body, conn)

      response = html_response(conn, 200)
      assert response =~ Phoenix.HTML.safe_to_string(news_entry.title)
      assert response =~ rewritten_news_body
      assert response =~ Phoenix.HTML.safe_to_string(news_entry.more_information)
      assert breadcrumbs_include?(response, ["News", news_entry_title])
   end

    test "renders a preview of the requested news entry", %{conn: conn} do
      news_entry = news_entry_factory(1)
      conn = get(conn, news_entry_path(conn, :show, news_entry) <> "?preview&vid=112&nid=3518")
      assert html_response(conn, 200) =~ "Between Forge Park/495 and Readville Stations for 8 Weekends 112"
    end

    test "includes Recent News suggestions", %{conn: conn} do
      news_entry = news_entry_factory(1)

      conn = get conn, news_entry_path(conn, :show, news_entry)

      body = html_response(conn, 200)
      assert body =~ "New Early Morning Bus Routes Begin April 1"
      assert body =~ "Art by Boston-Area Teens to Premiere"
      assert body =~ "Extra Transit Service Saturday"
      assert body =~ "AFC 2.0 to Support Faster Trips"
    end

    test "retains params and redirects with correct status code when CMS returns a native redirect", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "redirected-url") <> "?preview&vid=999"
      assert conn.status == 301
      assert Plug.Conn.get_resp_header(conn, "location") == ["/news/date/title?preview=&vid=999"]
    end

    test "renders a 404 given an valid id but mismatching content type", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "3268")
      assert conn.status == 404
    end

    test "renders a 404 given an invalid id", %{conn: conn} do
      conn = get conn, news_entry_path(conn, :show, "2018", "invalid-news-entry")
      assert conn.status == 404
    end
  end
end
