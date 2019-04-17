import React, { ReactElement } from "react";
import { Stop, Route } from "../../__v3api";
import TabComponent from "./Tab";
import { Tab, TypedRoutes, RouteWithDirections } from "./__stop";
import { parkingIcon, modeIcon } from "../../helpers/icon";
import accessible from "./StopAccessibilityIcon";
import { Dispatch, clickRoutePillAction } from "../state";
import { modeByV3ModeType } from "../../components/ModeFilter";

interface Props {
  stop: Stop;
  routes: TypedRoutes[];
  tabs: Tab[];
  zoneNumber: string;
  dispatch?: Dispatch;
}

const subwayModeIds = [
  "Blue",
  "Green",
  "Green-B",
  "Green-C",
  "Green-D",
  "Green-E",
  "Mattapan",
  "Orange",
  "Red"
];

const parking = ({
  // eslint-disable-next-line typescript/camelcase
  parking_lots: parkingLots
}: Stop): ReactElement<HTMLElement> | false =>
  parkingLots.length > 0 && (
    <a href="#parking" className="m-stop-page__header-feature">
      <span className="m-stop-page__icon">
        {parkingIcon("c-svg__icon-parking-default")}
      </span>
    </a>
  );

const modeType = (modeId: string): string => {
  if (modeId.startsWith("CR-")) return "CR";

  if (subwayModeIds.includes(modeId)) return modeId;

  return "Bus";
};

const modeIconFeature = (
  { id, type }: Route,
  dispatch?: Dispatch
): ReactElement<HTMLElement> => (
  <a
    href="#route-card-list"
    onClick={() =>
      dispatch && dispatch(clickRoutePillAction(modeByV3ModeType[type]))
    }
    key={modeType(id)}
    className="m-stop-page__header-feature"
  >
    <span className="m-stop-page__icon">{modeIcon(id)}</span>
  </a>
);

const iconableRoutesForType = ({
  // eslint-disable-next-line typescript/camelcase
  group_name,
  routes
}: TypedRoutes): RouteWithDirections[] => {
  // eslint-disable-next-line typescript/camelcase
  if (group_name === "subway") return routes;

  return routes.length ? [routes[0]] : [];
};

const iconableRoutes = (typedRoutes: TypedRoutes[]): RouteWithDirections[] =>
  typedRoutes.reduce(
    (acc: RouteWithDirections[], typeAndRoutes: TypedRoutes) =>
      acc.concat(iconableRoutesForType(typeAndRoutes)),
    []
  );

const modes = (
  typedRoutes: TypedRoutes[],
  dispatch?: Dispatch
): ReactElement<HTMLElement> | null => (
  <>
    {iconableRoutes(typedRoutes).map(({ route }) =>
      modeIconFeature(route, dispatch)
    )}
  </>
);

const crZone = (
  zoneNumber: string,
  dispatch?: Dispatch
): ReactElement<HTMLElement> | false =>
  !!zoneNumber &&
  zoneNumber.length > 0 && (
    <a
      href="#route-card-list"
      onClick={() =>
        dispatch && dispatch(clickRoutePillAction("commuter_rail"))
      }
      className="m-stop-page__header-feature"
    >
      <span className="m-stop-page__icon c-icon__cr-zone">
        {`Zone ${zoneNumber}`}
      </span>
    </a>
  );

const features = (
  stop: Stop,
  routes: TypedRoutes[],
  zoneNumber: string,
  dispatch?: Dispatch
): ReactElement<HTMLElement> => (
  <div className="m-stop-page__header-features">
    {modes(routes, dispatch)}
    {crZone(zoneNumber, dispatch)}
    {accessible(stop)}
    {parking(stop)}
  </div>
);

const nameUpcaseClass = (routes: TypedRoutes[]): string =>
  routes.length === 1 && routes[0].group_name === "bus"
    ? ""
    : "m-stop-page__name--upcase";

const Header = ({
  stop,
  routes,
  tabs,
  zoneNumber,
  dispatch
}: Props): ReactElement<HTMLElement> => (
  <div className="m-stop-page__header">
    <div className="m-stop-page__header-container">
      <h1 className={`m-stop-page__name ${nameUpcaseClass(routes)}`}>
        {stop.name}
      </h1>

      {features(stop, routes, zoneNumber, dispatch)}

      <div className="header-tabs">
        {tabs.map(tab => (
          <TabComponent key={tab.id} tab={tab} />
        ))}
      </div>
    </div>
  </div>
);

export default Header;
