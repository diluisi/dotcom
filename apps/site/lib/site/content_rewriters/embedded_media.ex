defmodule Site.ContentRewriters.EmbeddedMedia do
  @moduledoc """
  Extract CMS embed attributes, media classes, captions,
  and other details from processed <figure> HTML. All HTML is already
  sanitized and scrubbed prior to being re-parsed here.
  """

  defstruct [
    alignment: :none,
    caption: nil,
    element: "",
    link_attrs: [],
    size: :full,
    type: :image
  ]

  @valid_sizes [:full, :half, :third]
  @valid_types [:image]

  @type t :: %__MODULE__{
    alignment: :left | :right | :none,
    caption: Floki.html_tree | String.t,
    element: Floki.html_tree,
    link_attrs: list(),
    size: atom(),
    type: atom()
  }

  @spec parse(Floki.html_tree) :: t
  def parse({_, attributes, children}) do

    media_element = get_media(children)
    media_classes = children
    |> Floki.attribute(".media", "class")
    |> List.first
    |> String.split

    %__MODULE__{
      alignment: get_alignment(attributes),
      caption: get_caption(children),
      element: media_element,
      link_attrs: get_link(children),
      size: get_attribute(media_classes, :size),
      type: get_attribute(media_classes, :type)
    }
  end

  @doc """
  Reconstrust the figure element with BEM classes and the (link->embed)+caption elements;
  process the children normally (ensures images get the img-fluid class, etc). Also,
  wrap the media element in a rebuilt link, if link information is available.
  """
  @spec build(t) :: Floki.html_tree
  def build(%__MODULE__{type: type, size: size} = media)
  when size in @valid_sizes and type in @valid_types do

    media_embed = case media.link_attrs do
      [_ | _] -> {"a", media.link_attrs, media.element}
      _ -> media.element
    end

    {
      "figure",
      [{
        "class", "c-media " <>
          "c-media--type-#{media.type} " <>
          "c-media--size-#{media.size} " <>
          "c-media--align-#{media.alignment}"
      }],
      [
        media_embed,
        media.caption
      ]
    }
  end
  def build(_) do
    Floki.parse(~s(<div class="incompatible-media"></div>))
  end

  @spec get_media(Floki.html_tree) :: Floki.html_tree | nil
  defp get_media(wrapper_children) do
    # Isolate the actual embedded media element. Add BEM class.
    case Floki.find(wrapper_children, ".media-content > *:first-child") do
      [media| _] -> Site.FlokiHelpers.add_class(media, ["c-media__media-element"])
      [] -> nil
    end
  end

  # Determine if there is a caption and return it. Add BEM class.
  @spec get_caption(Floki.html_tree) :: Floki.html_tree | nil
  defp get_caption(wrapper_children) do
    case Floki.find(wrapper_children, "figcaption") do
      [caption | _] -> Site.FlokiHelpers.add_class(caption, ["c-media__caption"])
      [] -> ""
    end
  end

  # Determine if there is a link and capture certain attributes.
  @spec get_link(Floki.html_tree) :: list() | nil
  defp get_link(wrapper_children) do
    case Floki.find(wrapper_children, ".media-link") do
      [{_, _, _} = link | _] -> [
        {"class", "c-media__link"},
        {"href", Floki.attribute(link, "href")},
        {"target", Floki.attribute(link, "target")}]
      [] ->
        nil
    end
  end

  # Parse wrapper classes for alignment value.
  @spec get_alignment(list()) :: :left | :right | :none
  defp get_alignment([{"class", wrapper_classes}]) do
    classes = String.split(wrapper_classes)
    cond do
      "align-left" in classes -> :left
      "align-right" in classes -> :right
      true -> :none
    end
  end

  # Parse media element class for size and type.
  @spec get_attribute(list(), :size | :type) :: atom()
  defp get_attribute(classes, :size) do
    cond do
      "media--view-mode-full" in classes -> :full
      "media--view-mode-half" in classes -> :half
      "media--view-mode-third" in classes -> :third
      true -> :unknown
    end
  end
  defp get_attribute(classes, :type) do
    if "media--type-image" in classes do
      :image
    else
      :unknown
    end
  end
end
