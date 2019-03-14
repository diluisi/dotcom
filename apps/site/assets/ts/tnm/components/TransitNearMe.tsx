import React, { useReducer, ReactElement } from "react";
import TransitNearMeMap from "./TransitNearMeMap";
import RoutesSidebar from "./RoutesSidebar";
import StopsSidebar from "./StopsSidebar";
import { TNMRoute, TNMStop, StopWithRoutes } from "./__tnm";
import { MapData } from "../../app/googleMaps/__googleMaps";
import { reducer, initialState, SelectedStopType } from "../state";

interface Props {
  mapData: MapData;
  mapId: string;
  routeSidebarData: TNMRoute[];
  stopSidebarData: StopWithRoutes[];
}

export const getSelectedStop = (
  stopSidebarData: StopWithRoutes[],
  selectedStopId: SelectedStopType
): TNMStop | undefined => {
  const stopWithRoute = stopSidebarData.find(
    data => data.stop.id === selectedStopId
  );
  return stopWithRoute ? stopWithRoute.stop : undefined;
};

const TransitNearMe = ({
  mapData,
  mapId,
  routeSidebarData,
  stopSidebarData
}: Props): ReactElement<HTMLElement> => {
  const [state, dispatch] = useReducer(reducer, initialState);
  const selectedStop = getSelectedStop(stopSidebarData, state.selectedStopId);
  return (
    <div className="m-tnm">
      {state.routesView ? (
        <RoutesSidebar
          selectedStop={selectedStop}
          selectedStopId={state.selectedStopId}
          dispatch={dispatch}
          data={routeSidebarData}
          shouldFilterStopCards={state.shouldFilterStopCards}
        />
      ) : (
        <StopsSidebar
          selectedStop={selectedStop}
          selectedStopId={state.selectedStopId}
          dispatch={dispatch}
          data={stopSidebarData}
          shouldFilterStopCards={state.shouldFilterStopCards}
        />
      )}
      <div
        id={mapId}
        className="m-tnm__map"
        role="application"
        aria-label="Map with stops"
      />
      <TransitNearMeMap
        selectedStopId={state.selectedStopId}
        dispatch={dispatch}
        mapElementId={mapId}
        initialData={mapData}
        shouldCenterMapOnSelectedStop={state.shouldCenterMapOnSelectedStop}
      />
    </div>
  );
};

export default TransitNearMe;
