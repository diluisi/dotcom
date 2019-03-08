defmodule SiteWeb.PlacesController do
  @moduledoc """
  Routes for requesting data from Google Maps.
  """
  use SiteWeb, :controller
  alias GoogleMaps.{Geocode, Place, Place.AutocompleteQuery}
  alias Plug.Conn

  @spec autocomplete(Conn.t(), map) :: Conn.t()
  def autocomplete(conn, %{"input" => input, "hit_limit" => hit_limit_str, "token" => token}) do
    with {hit_limit, ""} <- Integer.parse(hit_limit_str),
         {:ok, predictions} <-
           Place.autocomplete(%AutocompleteQuery{
             input: input,
             hit_limit: hit_limit,
             session_token: token
           }) do
      json(conn, %{predictions: Poison.encode!(predictions)})
    else
      {:error, :internal_error} ->
        return_internal_error(conn)

      {:error, :zero_results} ->
        return_zero_results_error(conn)

      _ ->
        return_invalid_arguments_error(conn)
    end
  end

  @spec details(Conn.t(), map) :: Conn.t()
  def details(conn, %{"place_id" => place_id}) do
    with {:ok, results} <- Geocode.geocode_by_place_id(place_id) do
      json(conn, %{result: results |> List.first() |> Poison.encode!()})
    else
      {:error, :internal_error} ->
        return_internal_error(conn)

      {:error, :zero_results} ->
        return_zero_results_error(conn)
    end
  end

  @spec reverse_geocode(Conn.t(), map) :: Conn.t()
  def reverse_geocode(conn, params) do
    with {:ok, latitude, longitude} <- parse_location(params) do
      {:ok, results} = Geocode.reverse_geocode(latitude, longitude)
      json(conn, %{results: Poison.encode!(results)})
    else
      :invalid_lat_lng ->
        return_invalid_arguments_error(conn)

      {:error, :internal_error} ->
        return_internal_error(conn)

      {:error, :zero_results} ->
        return_zero_results_error(conn)
    end
  end

  defp parse_location(%{"latitude" => latitude_str, "longitude" => longitude_str}) do
    with {latitude, ""} <- Float.parse(latitude_str),
         {longitude, ""} <- Float.parse(longitude_str) do
      {:ok, latitude, longitude}
    else
      _ ->
        :invalid_lat_lng
    end
  end

  defp return_internal_error(conn),
    do: return_error(conn, :internal_server_error, "Internal error")

  defp return_invalid_arguments_error(conn),
    do: return_error(conn, :bad_request, "Invalid arguments")

  defp return_zero_results_error(conn),
    do: return_error(conn, :internal_server_error, "Zero results")

  defp return_error(conn, response_code, message) do
    conn
    |> Conn.put_status(response_code)
    |> json(%{error: message})
  end
end
