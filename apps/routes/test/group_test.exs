defmodule Routes.GroupTest do
  use ExUnit.Case, async: true
  alias Routes.Route

  @light_rail %Route{
    type: 0,
    id: "light",
    name: "light rail"
  }
  @subway %Route{
    type: 1,
    id: "subway",
    name: "subway"
  }
  @rail %Route{
    type: 2,
    id: "rail",
    name: "rail"
  }
  @bus %Route{
    type: 3,
    id: "bus",
    name: "bus"
  }
  @boat %Route{
    type: 4,
    id: "boat",
    name: "boat"
  }

  test ".group groups routes by their type" do
    assert Routes.Group.group([@light_rail, @subway, @rail, @bus, @boat]) == %{
      subway: [@light_rail, @subway],
      commuter_rail: [@rail],
      bus: [@bus],
      other: [@boat]
    }
  end
end
