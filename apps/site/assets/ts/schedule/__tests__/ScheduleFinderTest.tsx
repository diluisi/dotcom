import React from "react";
import { mount } from "enzyme";
import ScheduleFinder from "../components/ScheduleFinder";
import { EnhancedRoute } from "../../__v3api";
import {
  RoutePatternsByDirection,
  ServiceInSelector
} from "../components/__schedule";

const services: ServiceInSelector[] = [
  {
    valid_days: [1, 2, 3, 4, 5],
    typicality: "typical_service",
    type: "weekday",
    start_date: "2019-07-08",
    removed_dates_notes: {},
    removed_dates: [],
    name: "Weekday",
    id: "BUS319-J-Wdy-02",
    end_date: "2019-08-30",
    description: "Weekday schedule",
    added_dates_notes: {},
    added_dates: [],
    rating_start_date: "2019-06-25",
    rating_end_date: "2019-10-25",
    rating_description: "Test",
    "default_service?": true
  },
  {
    valid_days: [6],
    typicality: "typical_service",
    type: "saturday",
    start_date: "2019-07-13",
    removed_dates_notes: {},
    removed_dates: [],
    name: "Saturday",
    id: "BUS319-K-Sa-02",
    end_date: "2019-08-31",
    description: "Saturday schedule",
    added_dates_notes: {},
    added_dates: [],
    rating_start_date: "2019-06-25",
    rating_end_date: "2019-10-25",
    rating_description: "Test",
    "default_service?": false
  },
  {
    valid_days: [7],
    typicality: "typical_service",
    type: "sunday",
    start_date: "2019-07-14",
    removed_dates_notes: {},
    removed_dates: [],
    name: "Sunday",
    id: "BUS319-L-Su-02",
    end_date: "2019-08-25",
    description: "Sunday schedule",
    added_dates_notes: {},
    added_dates: [],
    rating_start_date: "2019-06-25",
    rating_end_date: "2019-10-25",
    rating_description: "Test",
    "default_service?": false
  }
];

const today = "2019-12-05";

const route: EnhancedRoute = {
  alert_count: 0,
  description: "",
  direction_destinations: { 0: "Oak Grove", 1: "Forest Hills" },
  direction_names: { 0: "Inbound", 1: "Outbound" },
  header: "",
  id: "Orange",
  long_name: "Orange Line",
  name: "Orange",
  type: 1
};

const stops = {
  "1": [
    {
      name: "SL",
      id: "741",
      is_closed: false,
      zone: "1"
    },
    {
      name: "Abc",
      id: "123",
      is_closed: false,
      zone: null
    },
    {
      name: "Def",
      id: "456",
      is_closed: false,
      zone: null
    },
    {
      name: "Wellington",
      id: "place-welln",
      is_closed: true,
      zone: null
    }
  ],
  "0": [
    {
      name: "Wellington",
      id: "place-welln",
      is_closed: true,
      zone: null
    },
    {
      name: "Abc",
      id: "123",
      is_closed: false,
      zone: null
    },
    {
      name: "SL",
      id: "741",
      is_closed: false,
      zone: "1"
    }
  ]
};

const routePatternsByDirection = {
  "0": [
    {
      typicality: 1,
      time_desc: "School Trip",
      shape_id: "9840004",
      route_id: "CR-Fitchburg",
      representative_trip_id: "CR-Weekday-Spring-19-401",
      name: "North Station - Wachusett",
      headsign: "Wachusett",
      id: "CR-Fitchburg-0-0",
      direction_id: 0
    }
  ],
  "1": [
    {
      typicality: 1,
      time_desc: "School Trip",
      shape_id: "9840003",
      route_id: "CR-Fitchburg",
      representative_trip_id: "CR-Weekday-Spring-19-400",
      name: "Wachusett - North Station",
      headsign: "North Station",
      id: "CR-Fitchburg-0-1",
      direction_id: 1
    }
  ]
} as RoutePatternsByDirection;

describe("ScheduleFinder", () => {
  const mountComponent = () =>
    mount(
      <ScheduleFinder
        route={route}
        stops={stops}
        directionId={0}
        services={services}
        routePatternsByDirection={routePatternsByDirection}
        today={today}
        scheduleNote={null}
      />
    );

  it("matches snapshot", () => {
    const wrapper = mountComponent();
    expect(wrapper.debug()).toMatchSnapshot();
  });

  it("opens the schedule modal via the origin modal", () => {
    const wrapper = mountComponent();

    // Click on the SelectContainer for the origin select
    wrapper
      .find("SelectContainer")
      .last()
      // @ts-ignore -- types for `invoke` are too restrictive?
      .invoke("handleClick")();
    wrapper
      .find(".schedule-finder__origin-list-item")
      .at(1)
      .simulate("click");

    // Schedule modal should be open with the chosen origin selected
    expect(
      wrapper
        .find(".schedule-finder--modal select")
        .last()
        .prop("value")
    ).toEqual("123");
  });

  it("clears the selected origin when the direction is changed", () => {
    const wrapper = mountComponent();

    wrapper
      .find("select")
      .last()
      .simulate("change", { target: { value: "123" } });
    wrapper
      .find("select")
      .first()
      .simulate("change", { target: { value: "1" } });

    expect(
      wrapper
        .find("select")
        .last()
        .prop("value")
    ).toEqual("");
  });

  it("changes the available origins when the direction is changed", () => {
    const wrapper = mountComponent();
    expect(
      wrapper
        .find("select")
        .last()
        .text()
    ).not.toContain("Def");

    wrapper
      .find("select")
      .first()
      .simulate("change", { target: { value: "1" } });

    expect(
      wrapper
        .find("select")
        .last()
        .text()
    ).toContain("Def");
  });
});
