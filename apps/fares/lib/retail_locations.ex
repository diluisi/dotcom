defmodule Fares.RetailLocations do
  alias __MODULE__.Location
  alias __MODULE__.Data

  @locations Data.build_r_tree()

  @doc """
    Takes a latitude and longitude and returns the four closest retail locations for purchasing fares.
  """
  @spec get_nearby(Util.Position.t) :: [{Location.t, float}]
  def get_nearby(lat_long) do
    @locations
    |> Data.k_nearest_neighbors(lat_long, 4)
    |> Enum.map(fn l -> {l, Util.Distance.haversine(l, lat_long)} end)
  end
end
