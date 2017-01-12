defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  @spec all() :: [Alerts.Alert.t]
  def all do
    cache nil, fn _ ->
      V3Api.Alerts.all().data
      |> Enum.map(fn alert ->
        Task.async(fn ->
          alert
          |> Alerts.Parser.parse
          |> include_parents
        end)
      end)
      |> Enum.map(&Task.await/1)
    end
  end

  @spec by_id(String.t) :: Alerts.Alert.t | nil
  def by_id(id) do
    all()
    |> Enum.find(&(&1.id == id))
  end

  @spec banner() :: Alerts.Banner.t | nil
  def banner() do
    {:ok, result} = cache(&V3Api.Alerts.all/0, &do_banner/1)
    result
  end

  @spec do_banner((() -> JsonApi.t)) :: {:ok, Alerts.Banner.t | nil}
  def do_banner(alert_fn) do
    result = alert_fn.().data
      |> Enum.flat_map(&build_banner/1)
      |> List.first
    {:ok, result}
  end

  defp include_parents(alert) do
    # For alerts which are tied to a child stop, look up the parent stop and
    # also include it as an informed entity.
    %{alert |
      informed_entity: Enum.flat_map(alert.informed_entity, &include_ie_parents/1)
    }
  end

  defp include_ie_parents(%{stop: nil} = ie) do
    [ie]
  end

  defp include_ie_parents(%{stop: stop_id} = ie) do
    stop_id
    |> stop_ids
    |> Enum.map(&(%{ie | stop: &1}))
  end

  defp stop_ids(stop_id) do
    ConCache.get_or_store(:alerts_parent_ids, stop_id, fn ->
      case V3Api.Stops.by_gtfs_id(stop_id) do
        %JsonApi{
          data: [
            %JsonApi.Item{
              relationships: %{
                "parent_station" => [%JsonApi.Item{id: parent_id}]}}]} ->
          [stop_id, parent_id]
        _ -> [stop_id]
      end
    end)
  end

  @spec build_banner(JsonApi.Item.t) :: [Alerts.Banner.t]
  defp build_banner(%JsonApi.Item{
        id: id,
        attributes: %{
          "banner" => title,
          "description" => description
        }}) when title != nil do
    [
      %Alerts.Banner{
        id: id,
        title: title,
        description: description}
    ]
  end
  defp build_banner(%JsonApi.Item{}) do
    []
  end
end
