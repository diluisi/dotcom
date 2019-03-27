defmodule GoogleMaps.Place.Prediction do
  @moduledoc """
  Prediction result from a Place lookup.
  """

  @type t :: %__MODULE__{
          description: String.t(),
          id: String.t(),
          matched_substrings: [map()],
          place_id: String.t(),
          reference: String.t(),
          structured_formatting: map,
          terms: [map()],
          types: [String.t()]
        }

  defstruct [
    :description,
    :id,
    :matched_substrings,
    :place_id,
    :reference,
    :structured_formatting,
    :terms,
    :types
  ]

  @spec new(map) :: t()
  def new(%{
        "description" => description,
        "id" => id,
        "matched_substrings" => matched_substrings,
        "place_id" => place_id,
        "reference" => reference,
        "structured_formatting" => structured_formatting,
        "terms" => terms,
        "types" => types
      }) do
    %__MODULE__{
      description: description,
      id: id,
      matched_substrings: matched_substrings,
      place_id: place_id,
      reference: reference,
      structured_formatting: structured_formatting,
      terms: terms,
      types: types
    }
  end
end
