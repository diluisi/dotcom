defmodule Content.CMS.Static do
  @moduledoc """

  Emulates Drupal REST API (both native and Views-based)

  """
  @behaviour Content.CMS

  alias Content.Helpers
  alias Content.NewsEntry
  alias Poison.Parser

  # Views REST export responses with fully-loaded objects

  def events_response do
    parse_json("cms/events.json")
  end

  def banners_response do
    parse_json("cms/banners.json")
  end

  def search_response do
    parse_json("cms/search.json")
  end

  def search_response_empty do
    parse_json("cms/search-empty.json")
  end

  def whats_happening_response do
    parse_json("cms/whats-happening.json")
  end

  def route_pdfs_response do
    parse_json("cms/route-pdfs.json")
  end

  # Small, teaser-based responses from CMS API

  def teaser_response do
    parse_json("cms/teasers.json")
  end

  def teaser_news_entry_response do
    parse_json("cms/teasers_news_entry.json")
  end

  def teaser_guides_response do
    parse_json("cms/teasers_guides.json")
  end

  def teaser_project_response do
    parse_json("cms/teasers_project.json")
  end

  def teaser_featured_projects_response do
    parse_json("cms/teasers_project_featured.json")
  end

  def teaser_project_update_response do
    parse_json("cms/teasers_project_update.json")
  end

  # Repositories of multiple, full-object responses for convenience

  def news_repo do
    parse_json("repo/news.json")
  end

  def project_repo do
    parse_json("repo/projects.json")
  end

  def project_update_repo do
    parse_json("repo/project-updates.json")
  end

  # Core (entity:node) responses

  def all_paragraphs_response do
    parse_json("landing_page_with_all_paragraphs.json")
  end

  def basic_page_response do
    parse_json("basic_page_no_sidebar.json")
  end

  def basic_page_with_sidebar_response do
    parse_json("basic_page_with_sidebar.json")
  end

  def basic_page_no_alias_response do
    parse_json("basic_page_with_sidebar_no_alias.json")
  end

  def landing_page_response do
    parse_json("landing_page.json")
  end

  def person_response do
    parse_json("person.json")
  end

  def redirect_response do
    parse_json("redirect.json")
  end

  def redirect_with_query_response do
    parse_json("redirect_with_query%3Fid%3D5.json")
  end

  # Partials (paragraph library) response

  def paragraph_response do
    parse_json("_paragraph.json")
  end

  @impl true
  def view(path, params)

  def view("/cms/recent-news", current_id: id) do
    filtered_recent_news = Enum.reject(news_repo(), &match?(%{"nid" => [%{"value" => ^id}]}, &1))

    recent_news = Enum.take(filtered_recent_news, NewsEntry.number_of_recent_news_suggestions())

    {:ok, recent_news}
  end

  def view("/cms/recent-news", _) do
    {:ok, Enum.take(news_repo(), NewsEntry.number_of_recent_news_suggestions())}
  end

  def view("/basic_page_no_sidebar", _) do
    {:ok, basic_page_response()}
  end

  def view("/cms/news", id: id) do
    news_entry = filter_by(news_repo(), "nid", id)
    {:ok, news_entry}
  end

  def view("/cms/news", migration_id: "multiple-records") do
    {:ok, news_repo()}
  end

  def view("/cms/news", migration_id: id) do
    news = filter_by(news_repo(), "field_migration_id", id)
    {:ok, news}
  end

  def view("/cms/news", page: _page) do
    record = List.first(news_repo())
    {:ok, [record]}
  end

  def view("/news/incorrect-pattern", _) do
    {:ok, Enum.at(news_repo(), 1)}
  end

  def view("/news/date/title", _) do
    {:ok, Enum.at(news_repo(), 1)}
  end

  def view("/news/2018/news-entry", _) do
    {:ok, List.first(news_repo())}
  end

  def view("/news/redirected-url", params) do
    redirect("/news/date/title", params, 301)
  end

  def view("/cms/events", meeting_id: "multiple-records") do
    {:ok, events_response()}
  end

  def view("/cms/events", meeting_id: id) do
    events = filter_by(events_response(), "field_meeting_id", id)
    {:ok, events}
  end

  def view("/cms/events", id: id) do
    {:ok, filter_by(events_response(), "nid", id)}
  end

  def view("/events/incorrect-pattern", _) do
    {:ok, Enum.at(events_response(), 1)}
  end

  def view("/events/date/title", _) do
    {:ok, Enum.at(events_response(), 1)}
  end

  def view("/events/redirected-url", params) do
    redirect("/events/date/title", params, 301)
  end

  def view("/cms/events", _opts) do
    {:ok, events_response()}
  end

  def view("/cms/search", q: "empty", page: 0) do
    {:ok, search_response_empty()}
  end

  def view("/cms/search", _opts) do
    {:ok, search_response()}
  end

  def view("/projects/project-name", _) do
    {:ok, Enum.at(project_repo(), 1)}
  end

  def view("/porjects/project-name", _) do
    {:ok, Enum.at(project_repo(), 1)}
  end

  def view("/projects/redirected-project", params) do
    redirect("/projects/project-name", params, 301)
  end

  def view("/projects/3004/update/3174", _) do
    {:ok, Enum.at(project_update_repo(), 1)}
  end

  def view("/projects/project-name/update/project-progress", _) do
    {:ok, Enum.at(project_update_repo(), 1)}
  end

  def view("/projects/project-deleted/update/project-deleted-progress", _) do
    project_info = %{
      "field_project" => [
        %{
          "target_id" => 3004,
          "target_type" => "node",
          "target_uuid" => "5d55a7f8-22da-4ce8-9861-09602c64c7e4",
          "url" => "/projects/project-deleted"
        }
      ]
    }

    {:ok,
     project_update_repo()
     |> Enum.at(0)
     |> Map.merge(project_info)}
  end

  def view("/projects/redirected-project/update/not-redirected-update", _) do
    {:ok, Enum.at(project_update_repo(), 2)}
  end

  def view("/projects/project-name/update/redirected-update", params) do
    redirect("/projects/project-name/update/project-progress", params, 301)
  end

  def view("/cms/whats-happening", _) do
    {:ok, whats_happening_response()}
  end

  def view("/cms/important-notices", _) do
    {:ok, banners_response()}
  end

  def view("/landing_page_with_all_paragraphs", _) do
    {:ok, all_paragraphs_response()}
  end

  def view("/landing_page", _) do
    {:ok, landing_page_response()}
  end

  def view("/basic_page_with_sidebar", _) do
    {:ok, basic_page_with_sidebar_response()}
  end

  def view("/redirect_node", _) do
    {:ok, redirect_response()}
  end

  def view("/redirect_node_with_query%3Fid%3D5", _) do
    {:ok, redirect_with_query_response()}
  end

  def view("/redirect_node_with_query", %{"id" => "6"}) do
    {:ok, redirect_with_query_response()}
  end

  def view("/person", _) do
    {:ok, person_response()}
  end

  # Nodes without a path alias OR CMS redirect
  def view("/node/3183", _) do
    {:ok, basic_page_no_alias_response()}
  end

  def view("/node/3519", _) do
    {:ok, Enum.at(news_repo(), 0)}
  end

  def view("/node/3268", _) do
    {:ok, Enum.at(events_response(), 0)}
  end

  def view("/node/3004", _) do
    {:ok, Enum.at(project_repo(), 0)}
  end

  def view("/node/3005", _) do
    {:ok, Enum.at(project_update_repo(), 0)}
  end

  # Paths that return CMS redirects (path alias exists)
  def view("/node/3518", params) do
    redirect("/news/2018/news-entry", params, 301)
  end

  def view("/node/3458", params) do
    redirect("/events/date/title", params, 301)
  end

  def view("/node/3480", params) do
    redirect("/projects/project-name", params, 301)
  end

  def view("/node/3174", params) do
    redirect("/projects/project-name/updates/project-progress", params, 301)
  end

  def view("/cms/route-pdfs/87", _) do
    {:ok, route_pdfs_response()}
  end

  def view("/cms/route-pdfs/error", _) do
    {:error, :invalid_response}
  end

  def view("/cms/route-pdfs/" <> _route_id, _) do
    {:ok, []}
  end

  def view("/cms/teasers/guides", _) do
    {:ok, teaser_guides_response()}
  end

  def view("/cms/teasers/Guides/Red", sticky: 0) do
    {:ok, []}
  end

  def view("/cms/teasers", %{type: "project", sticky: 1}) do
    {:ok, teaser_featured_projects_response()}
  end

  def view("/cms/teasers", %{type: "project"}) do
    {:ok, teaser_project_response()}
  end

  def view("/cms/teasers", %{type: "project_update"}) do
    {:ok, teaser_project_update_response()}
  end

  def view("/cms/teasers", %{type: "news_entry"}) do
    {:ok, teaser_news_entry_response()}
  end

  def view("/cms/teasers/" <> route_id, params) when route_id != "NotFound" do
    filtered =
      teaser_response()
      |> filter_teasers(params)

    case Map.fetch(params, :items_per_page) do
      {:ok, count} ->
        {:ok, Enum.take(filtered, count)}

      :error ->
        {:ok, filtered}
    end
  end

  def view("/admin/content/paragraphs/" <> _paragraph_id, _) do
    {:ok, paragraph_response()}
  end

  def view("/redirected-url", params) do
    redirect("/different-url", params, 302)
  end

  def view("/invalid", _) do
    {:error, :invalid_response}
  end

  def view("/timeout", _) do
    {:error, :timeout}
  end

  def view(_, _) do
    {:error, :not_found}
  end

  @impl true
  def preview(node_id, revision_id)
  def preview(3518, vid), do: {:ok, do_preview(Enum.at(news_repo(), 1), vid)}
  def preview(5, vid), do: {:ok, do_preview(Enum.at(events_response(), 1), vid)}
  def preview(3480, vid), do: {:ok, do_preview(Enum.at(project_repo(), 1), vid)}
  def preview(3174, vid), do: {:ok, do_preview(Enum.at(project_update_repo(), 1), vid)}
  def preview(6, vid), do: {:ok, do_preview(basic_page_response(), vid)}

  @impl true
  def post("entity/node", body) do
    if String.contains?(body, "fails-to-create") do
      {:error, %{status_code: 422}}
    else
      body
      |> Parser.parse!()
      |> entity_type()
      |> successful_response()
    end
  end

  @impl true
  def update("node/" <> _id, body) do
    if String.contains?(body, "fails-to-update") do
      {:error, %{status_code: 422}}
    else
      body
      |> Parser.parse!()
      |> entity_type()
      |> successful_response()
    end
  end

  defp successful_response("event") do
    [event | _] = events_response()
    {:ok, event}
  end

  defp successful_response("news_entry") do
    [news_entry | _] = news_repo()
    {:ok, news_entry}
  end

  defp entity_type(%{"type" => [%{"target_id" => target_id}]}), do: target_id

  defp filter_by(map, key, value) do
    Enum.filter(map, &match?(%{^key => [%{"value" => ^value}]}, &1))
  end

  defp parse_json(filename) do
    file_path = [Path.dirname(__ENV__.file), "../../priv/", filename]

    file_path
    |> Path.join()
    |> File.read!()
    |> Parser.parse!()
  end

  # Generates multiple revisions on the fly for a single fixture
  @spec do_preview(map, integer | String.t() | nil) :: [map]
  defp do_preview(%{"title" => [%{"value" => title}]} = response, vid) do
    vid = Helpers.int_or_string_to_int(vid)

    revisions =
      for v <- [113, 112, 111] do
        %{response | "vid" => [%{"value" => v}], "title" => [%{"value" => "#{title} #{v}"}]}
      end

    cms_revision_filter(revisions, vid)
  end

  # Performs the CMS-side revision ID filtering
  @spec cms_revision_filter([map], integer | nil) :: [map]
  defp cms_revision_filter(revisions, vid)

  # When no vid is specified, all results are returned
  defp cms_revision_filter(revisions, nil) do
    revisions
  end

  # CMS will filter results to single matching result with vid
  defp cms_revision_filter(revisions, vid) do
    Enum.filter(revisions, &match?(%{"vid" => [%{"value" => ^vid}]}, &1))
  end

  def redirect(path, params, code) when params == %{}, do: {:error, {:redirect, code, [to: path]}}

  def redirect(path, params, code),
    do: redirect(path <> "?" <> URI.encode_query(params), %{}, code)

  defp filter_teasers(teasers, %{type: type, type_op: "not in"}) do
    Enum.reject(teasers, &filter_teaser?(&1, type))
  end

  defp filter_teasers(teasers, %{type: type}) do
    Enum.filter(teasers, &filter_teaser?(&1, type))
  end

  defp filter_teasers(teasers, %{}) do
    teasers
  end

  defp filter_teaser?(%{"type" => type}, type_atom), do: Atom.to_string(type_atom) === type
end
