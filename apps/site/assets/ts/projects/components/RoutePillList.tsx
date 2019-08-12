import React, { ReactElement } from "react";
import RouteIcon from "./RouteIcon";
import RoutePill from "./RoutePill";
import { Route } from "./__projects";
import { isSilverLine } from "../../helpers/silver-line";

interface Props {
  routes: Route[];
}

const busName = (id: string): string =>
  isSilverLine(id) ? "silver-line" : "bus";

export const routeToModeName = ({ mode, id }: Route): string => {
  switch (mode) {
    case "subway":
      if (id.toLowerCase().match(/^green/)) {
        return "green-line";
      }
      return id
        .toLowerCase()
        .replace(" ", "-")
        .concat("-line");
    case "commuter_rail":
      return "commuter-rail";
    case "ferry":
      return "ferry";
    default:
      return busName(id);
  }
};

const sortedDistinctModes = (strings: string[]): string[] => {
  const distinctModes = strings.reduce(
    (acc, str) => {
      if (acc.includes(str)) {
        return acc;
      }
      return acc.concat([str]);
    },
    [] as string[]
  );

  return distinctModes;
};

const RoutePillList = ({ routes }: Props): ReactElement<HTMLElement> => {
  const modeNames = sortedDistinctModes(routes.map(routeToModeName));
  return (
    <div className="m-route-pills">
      {modeNames.map(modeName => {
        switch (modeName) {
          case "bus":
            return (
              <RouteIcon
                key="route-pill-bus"
                tag="bus"
                extraClasses="c-featured-project__route-icon"
              />
            );
          case "silver-line":
            return (
              <span key="route-pill-silver-line">
                <RouteIcon
                  tag="bus"
                  extraClasses="c-featured-project__route-icon"
                />
                <RoutePill modeName="silver-line" />
              </span>
            );
          case "subway-line":
            return (
              <RouteIcon
                key="route-pill-subway"
                tag="subway"
                extraClasses="c-featured-project__route-icon"
              />
            );
          default:
            return (
              <RoutePill key={`route-pill-${modeName}`} modeName={modeName} />
            );
        }
      })}
    </div>
  );
};

export default RoutePillList;
