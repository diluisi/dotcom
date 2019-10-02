import React from "react";
import renderer from "react-test-renderer";
import {
  createReactRoot,
  enzymeToJsonWithoutProps
} from "../../app/helpers/testUtils";
import { mount } from "enzyme";
import {
  menuReducer as reducer,
  State,
  MenuAction as Action
} from "../components/direction/reducer";
import ScheduleDirection, {
  fetchMapData
} from "../components/ScheduleDirection";
import { EnhancedRoute } from "../../__v3api";
import { MapData } from "../../leaflet/components/__mapdata";
import { RoutePatternsByDirection, ShapesById } from "../components/__schedule";

const body =
  '<div id="body-wrapper"><div id="react-root"></div><div id="map-root"></div></div>';

const route = {
  type: 3,
  name: "route 1",
  long_name: "route 1 long name",
  id: "route-1",
  direction_names: {
    0: "Outbound",
    1: "Inbound"
  },
  direction_destinations: {
    0: "Begin",
    1: "End"
  },
  description: "key_bus_route",
  "custom_route?": false,
  header: "",
  alert_count: 0
} as EnhancedRoute;
const directionId = 1;
const routePatternsByDirection = {
  "0": [
    {
      typicality: 1,
      time_desc: null,
      shape_id: "shape-1",
      route_id: "route-1",
      representative_trip_id: "trip-1",
      name: "Pattern 1 - Dest",
      headsign: "Pattern 1",
      id: "pattern-1",
      direction_id: 0
    },
    {
      typicality: 1,
      time_desc: null,
      shape_id: "shape-3",
      route_id: "route-1",
      representative_trip_id: "trip-3",
      name: "Pattern 3 - Dest",
      headsign: "Pattern 3",
      id: "pattern-3",
      direction_id: 0
    },
    {
      typicality: 3,
      time_desc: null,
      shape_id: "shape-4",
      route_id: "route-1",
      representative_trip_id: "trip-4",
      name: "Pattern 4 - Dest",
      headsign: "Pattern 3",
      id: "pattern-4",
      direction_id: 0
    }
  ],
  "1": [
    {
      typicality: 2,
      time_desc: null,
      shape_id: "shape-2",
      route_id: "route-1",
      representative_trip_id: "trip-1",
      name: "Pattern 2 - Dest",
      headsign: "Pattern 2",
      id: "pattern-2",
      direction_id: 1
    }
  ]
} as RoutePatternsByDirection;
const shapesById = {
  "shape-1": {
    stop_ids: ["stop"],
    priority: 3,
    polyline: "xyz",
    name: "Shape 1",
    id: "shape-1",
    direction_id: 0
  },
  "shape-2": {
    stop_ids: ["stop"],
    priority: 3,
    polyline: "xyz",
    name: "Shape 2",
    id: "shape-2",
    direction_id: 1
  },
  "shape-3": {
    stop_ids: ["stop"],
    priority: 3,
    polyline: "xyz",
    name: "Shape 3",
    id: "shape-3",
    direction_id: 0
  }
} as ShapesById;

const state = {
  routePattern: routePatternsByDirection["0"][0],
  shape: shapesById["shape-1"],
  directionId: 0,
  shapesById: shapesById,
  routePatternsByDirection: routePatternsByDirection,
  routePatternMenuOpen: false,
  routePatternMenuAll: false,
  itemFocus: null
} as State;

/* eslint-disable @typescript-eslint/camelcase */
const mapData: MapData = {
  zoom: 16,
  width: 600,
  tile_server_url: "https://mbta-map-tiles-dev.s3.amazonaws.com",
  polylines: [],
  markers: [
    {
      icon: "vehicle-bordered-expanded",
      id: "vehicle-R-545CDFC5",
      latitude: 42.39786911010742,
      longitude: -71.13092041015625,
      rotation_angle: 90,
      tooltip_text: "Alewife train is on the way to Alewife",
      tooltip: null
    },
    {
      icon: "stop-circle-bordered-expanded",
      id: "stop-place-alfcl",
      latitude: 42.395428,
      longitude: -71.142483,
      rotation_angle: 0,
      tooltip: null,
      tooltip_text: "Alewife"
    }
  ],
  height: 600,
  default_center: {
    longitude: -71.05891,
    latitude: 42.360718
  }
};
/* eslint-enable typescript/camelcase */

const getComponent = () => (
  <ScheduleDirection
    route={route}
    directionId={directionId}
    routePatternsByDirection={routePatternsByDirection}
    shapesById={shapesById}
    mapData={mapData}
    stopListHtml={"line diagram content goes here"}
  />
);

const getSubwayComponent = () => (
  <ScheduleDirection
    mapData={mapData}
    route={{ ...route, type: 1 }}
    directionId={directionId}
    routePatternsByDirection={routePatternsByDirection}
    shapesById={shapesById}
    stopListHtml={"line diagram content goes here"}
  />
);

it("it renders a bus component", () => {
  createReactRoot();
  const tree = mount(getComponent());
  expect(enzymeToJsonWithoutProps(tree)).toMatchSnapshot();
});

it("it renders a subway component", () => {
  createReactRoot();
  const tree = mount(getSubwayComponent());
  expect(enzymeToJsonWithoutProps(tree)).toMatchSnapshot();
});

it("can change direction", () => {
  document.body.innerHTML = body;
  const component = getComponent();
  const wrapper = mount(component);
  expect(wrapper.find("#direction-name").text()).toBe("Inbound");
  wrapper.find("button").simulate("click");
  expect(wrapper.find("#direction-name").text()).toBe("Outbound");
});

it("can change route pattern for bus mode", () => {
  document.body.innerHTML = body;
  const component = getComponent();
  const wrapper = mount(component);
  wrapper.find("button").simulate("click");
  expect(
    wrapper.find(".m-schedule-direction__route-pattern--clickable").text()
  ).toBe("Pattern 1 SVG");
  expect(wrapper.find(".m-schedule-direction__menu").exists()).toEqual(false);
  wrapper
    .find(".m-schedule-direction__route-pattern--clickable")
    .simulate("click");
  expect(wrapper.find(".m-schedule-direction__menu").exists()).toEqual(true);
  wrapper.find("#route-pattern_pattern-3").simulate("click");
  expect(
    wrapper.find(".m-schedule-direction__route-pattern--clickable").text()
  ).toBe("Pattern 3 SVG");
  wrapper
    .find(".m-schedule-direction__route-pattern--clickable")
    .simulate("click");

  // get code coverage of keyboard navigation
  wrapper
    .find("#route-pattern_pattern-1")
    .simulate("keydown", { key: "ArrowRight" });

  wrapper
    .find("#route-pattern_pattern-3")
    .simulate("keydown", { key: "ArrowRight" });

  wrapper
    .find("#route-pattern_uncommon")
    .simulate("keydown", { key: "ArrowRight" });

  wrapper
    .find("#route-pattern_pattern-1")
    .simulate("keydown", { key: "ArrowLeft" });

  wrapper
    .find("#route-pattern_pattern-3")
    .simulate("keydown", { key: "ArrowLeft" });

  wrapper
    .find("#route-pattern_pattern-3")
    .simulate("keydown", { key: "Tab", shiftKey: true });

  wrapper.find("#route-pattern_pattern-3").simulate("keydown", { key: "X" });

  wrapper.find("#route-pattern_uncommon").simulate("click");

  wrapper.find("button").simulate("click");
});

it("can change route pattern for bus mode (accessible)", () => {
  document.body.innerHTML = body;
  const component = getComponent();
  const wrapper = mount(component);
  wrapper.find("button").simulate("click");
  expect(
    wrapper.find(".m-schedule-direction__route-pattern--clickable").text()
  ).toBe("Pattern 1 SVG");
  expect(wrapper.find(".m-schedule-direction__menu").exists()).toEqual(false);

  wrapper
    .find(".m-schedule-direction__route-pattern--clickable")
    .simulate("keyUp", { key: "Enter" });
  expect(wrapper.find(".m-schedule-direction__menu").exists()).toEqual(true);

  wrapper.find("#route-pattern_pattern-3").simulate("keyUp", { key: "Enter" });
  expect(
    wrapper.find(".m-schedule-direction__route-pattern--clickable").text()
  ).toBe("Pattern 3 SVG");
  wrapper
    .find(".m-schedule-direction__route-pattern--clickable")
    .simulate("click");

  wrapper.find("#route-pattern_uncommon").simulate("keyUp", { key: "Enter" });
});

it("reducer can change state correctly for closeRoutePatternMenu", () => {
  const previousState = { ...state, routePatternMenuOpen: true } as State;

  const action = { type: "closeRoutePatternMenu", payload: {} } as Action;

  const nextState = reducer(previousState, action);

  expect(nextState.routePatternMenuOpen).toEqual(false);
});

it("reducer can change state correctly for showAllRoutePatterns", () => {
  const previousState = { ...state, routePatternMenuAll: false } as State;

  const action = { type: "showAllRoutePatterns", payload: {} } as Action;

  const nextState = reducer(previousState, action);

  expect(nextState.routePatternMenuAll).toEqual(true);
});

describe("fetchMapData", () => {
  it("fetches data", () => {
    const spy = jest.fn();
    window.fetch = jest.fn().mockImplementation(
      () =>
        new Promise((resolve: Function) =>
          resolve({
            json: () => mapData,
            ok: true,
            status: 200,
            statusText: "OK"
          })
        )
    );

    return fetchMapData("1", 0, "2", spy).then(() => {
      expect(window.fetch).toHaveBeenCalledWith(
        "/schedules/map_api?id=1&direction_id=0&variant=2"
      );
      expect(spy).toHaveBeenCalledWith({
        type: "FETCH_STARTED"
      });
      expect(spy).toHaveBeenCalledWith({
        type: "FETCH_COMPLETE",
        payload: mapData
      });
    });
  });

  it("fails gracefully if fetch is unsuccessful", () => {
    const spy = jest.fn();
    window.fetch = jest.fn().mockImplementation(
      () =>
        new Promise((resolve: Function) =>
          resolve({
            json: () => "Internal Server Error",
            ok: false,
            status: 500,
            statusText: "INTERNAL SERVER ERROR"
          })
        )
    );

    return fetchMapData("1", 0, "2", spy).then(() => {
      expect(window.fetch).toHaveBeenCalledWith(
        "/schedules/map_api?id=1&direction_id=0&variant=2"
      );
      expect(spy).toHaveBeenCalledWith({
        type: "FETCH_STARTED"
      });
      expect(spy).toHaveBeenCalledWith({
        type: "FETCH_ERROR"
      });
    });
  });
});
