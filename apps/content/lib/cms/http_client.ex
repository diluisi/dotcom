defmodule Content.CMS.HTTPClient do
  @behaviour Content.CMS

  import Content.ExternalRequest, only: [process: 3, process: 4]

  @impl true
  def view(path, params) do
    params = Keyword.merge(params, [_format: "json"])
    process(:get, path, "", params)
  end

  @impl true
  def post(path, body) do
    process(:post, path, body)
  end

  @impl true
  def update(path, body) do
    process(:patch, path, body)
  end
end
