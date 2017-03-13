defmodule Content.Repo do
  @doc """

  Fetches a %Content.Page{} for a given path.

  """
  @spec page(String.t) :: {:ok, Content.Page.t} | {:error, any}
  def page(path, params \\ []) when is_binary(path) do
    params = put_in params[:_format], "json"

    with {:ok, full_url} <- build_url(path),
         {:ok, response} <- HTTPoison.get(full_url, [], params: params),
         %{status_code: 200, body: body} <- response,
         {:ok, page} <- Content.Parse.Page.parse(body) do
      case page do
        %Content.Page{} -> {:ok, Content.Page.rewrite_static_files(page)}
        list when is_list(list) -> {:ok, list}
      end
    else
      tuple = {:error, _} -> tuple
      error -> {:error, "while fetching page #{path}?#{URI.encode_query(params)}: #{inspect error}"}
    end
  end

  defp build_url(path) do
    case Content.Config.url(path) do
      nil -> {:error, "undefined Drupal root"}
      url -> {:ok, url}
    end
  end

  @spec all(String.t, map) :: list(Content.Page.t) | list
  def all(collection_path, params \\ %{}) do
    case Content.Repo.page(collection_path, params) do
      {:ok, records} -> records
      error -> raise Content.ErrorFetchingContent, message: error
    end
  end

  @spec get(String.t, integer) :: Content.Page.t | nil | no_return
  def get(collection_path, id) do
    case all(collection_path, id: id) do
      [record] -> record
      [] -> nil
    end
  end

  @spec get!(String.t, integer) :: Content.Page.t | no_return
  def get!(collection_path, id) do
    case all(collection_path, id: id) do
      [record] -> record
      [] -> raise Content.NoResultsError
    end
  end
end
