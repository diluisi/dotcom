defmodule Alerts.Repo do
  use RepoCache, ttl: :timer.minutes(1)

  alias Alerts.Cache.Store

  @spec all() :: [Alerts.Alert.t]
  def all do
    Store.all_alerts()
  end

  @spec banner() :: Alerts.Banner.t | nil
  def banner do
    Store.banner()
  end

  @spec by_route_ids([String.t]) :: [Alerts.Alert.t]
  def by_route_ids(route_ids) do
    route_ids
    |> Store.alert_ids_for_routes()
    |> Store.alerts()
  end
end
