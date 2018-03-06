defmodule Content.SearchResult.File do
  defstruct [
    title: "",
    url: "",
    mimetype: ""
  ]

  @type t :: %__MODULE__{
    title: String.t,
    url: String.t,
    mimetype: String.t
  }

  @spec build(map) :: t
  def build(result) do
    %__MODULE__{
      title: result["ts_filename"],
      url: link(result["ss_uri"]),
      mimetype: result["ss_filemime"]
    }
  end

  @spec link(String.t) :: String.t
  defp link(path) do
    path = String.replace(path, "public:/", Content.Config.static_path)
    Util.site_path(:static_url, [path])
  end
end
