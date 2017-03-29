defmodule Content.CMS.Static do
  @behaviour Content.CMS

  @recent_news File.read!("priv/recent-news.json")
  @basic_page File.read!("priv/accessibility.json")
  @project_update File.read!("priv/gov-center-project.json")

  def recent_news_response do
    @recent_news |> Poison.Parser.parse!
  end

  def basic_page_response do
    @basic_page |> Poison.Parser.parse!
  end

  def project_update_response do
    @project_update |> Poison.Parser.parse!
  end

  def view(path, params \\ [])
  def view("/recent-news", _) do
    {:ok, recent_news_response()}
  end
  def view("/accessibility", _) do
    {:ok, basic_page_response()}
  end
  def view("/gov-center-project", _) do
    {:ok, project_update_response()}
  end
  def view("/news/winter", _) do
    {:ok, recent_news_response() |> List.first}
  end
  def view(_, _) do
    {:error, "Not able to retrieve response"}
  end
end
