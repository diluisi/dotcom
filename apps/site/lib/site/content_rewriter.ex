defmodule Site.ContentRewriter do
  @moduledoc """
  Rewrites the content that comes from the CMS before rendering it to the page.
  """

  alias Site.ContentRewriters.{ResponsiveTables, LiquidObjects, Links}

  @doc """
  The main entry point for the various transformations we apply to CMS content
  before rendering to the page. The content is parsed by Floki and then traversed
  with a dispatch function that will identify nodes to be rewritten and pass
  them to the modules and functions responsible. See the Site.FlokiHelpers.traverse
  docs for more information about how the visitor function should work to
  traverse and manipulate the tree.
  """
  @spec rewrite(Phoenix.HTML.safe | String.t, Plug.Conn.t) :: Phoenix.HTML.safe
  def rewrite({:safe, content}, conn) do
    content
    |> Floki.parse
    |> Site.FlokiHelpers.traverse(&dispatch_rewrites(&1, conn))
    |> render
    |> Phoenix.HTML.raw
  end
  def rewrite(content, conn) when is_binary(content) do
    dispatch_rewrites(content, conn)
  end

  # necessary since foo |> Floki.parse |> Floki.raw_html blows up
  # if there are no HTML tags in foo.
  defp render(content) when is_binary(content), do: content
  defp render(content), do: Floki.raw_html(content)

  @spec dispatch_rewrites(Floki.html_tree | binary, Plug.Conn.t) :: Floki.html_tree | binary | nil
  defp dispatch_rewrites({"table", _, _} = element, conn) do
    element
    |> ResponsiveTables.rewrite_table()
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"a", _, _} = element, conn) do
    element
    |> Links.add_target_to_redirect()
    |> Links.add_preview_params(conn)
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"p", _, [{"iframe", _, _} | _]} = element, conn) do
    element
    |> add_class("iframe-container")
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"img", _, _} = element, conn) do
    element
    |> remove_style_attrs()
    |> add_class("img-fluid")
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites({"iframe", _, _} = element, conn) do
    element
    |> remove_style_attrs()
    |> set_iframe_class()
    |> rewrite_children(conn)
  end
  defp dispatch_rewrites(content, _conn) when is_binary(content) do
    Regex.replace(~r/\{\{(.*)\}\}/U, content, fn(_, obj) ->
      obj
      |> String.trim
      |> LiquidObjects.replace
    end)
  end
  defp dispatch_rewrites(_node, _conn) do
    nil
  end

  defp rewrite_children({name, attrs, children}, conn) do
    {name, attrs, Site.FlokiHelpers.traverse(children, &dispatch_rewrites(&1, conn))}
  end

  @spec set_iframe_class(Floki.html_tree) :: Floki.html_tree
  defp set_iframe_class({_, attrs, _} = element) do
    new_class = case Enum.find(attrs, fn {key, _} -> key == "src" end) do
      {"src", "https://www.google.com/maps" <> _} -> [" ", "iframe-full-width"]
      {"src", "https://livestream.com" <> _} -> [" ", "iframe-full-width"]
      _ -> []
    end
    add_class(element, ["iframe", new_class])
  end

  @spec remove_style_attrs(Floki.html_tree) :: Floki.html_tree
  defp remove_style_attrs({name, attrs, children}) do
    {name, Enum.reject(attrs, &remove_attr?(&1, name)), children}
  end

  @spec remove_attr?({String.t, String.t}, String.t) :: boolean
  defp remove_attr?({"height", _}, _), do: true
  defp remove_attr?({"width", _}, _), do: true
  defp remove_attr?({"style", _}, "iframe"), do: true
  defp remove_attr?(_, _), do: false

  @spec add_class(Floki.html_tree, iodata) :: Floki.html_tree
  defp add_class({name, attrs, children}, new_class) do
    attrs = case Enum.split_with(attrs, &match?({"class", _}, &1)) do
      {[], others} ->
        [{"class", new_class} | others]
      {[{"class", existing_class}], others} ->
        [{"class", [existing_class, " ", new_class]} | others]
    end
    {name, attrs, children}
  end
end
