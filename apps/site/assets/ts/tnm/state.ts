import * as googleMaps from "../app/googleMaps/state";

import { TNMMode } from "./components/__tnm";

export type SelectedStopType = string | null;

export const { clickMarkerAction } = googleMaps;

export const { clickCurrentLocationAction } = googleMaps;

interface State {
  selectedStopId: SelectedStopType;
  selectedModes: TNMMode[];
  shouldFilterStopCards: boolean;
  shouldCenterMapOnSelectedStop: boolean;
  routesView: boolean;
}

export type Dispatch = (action: StopAction | ModeAction) => void;

type StopActionType =
  | googleMaps.MapActionType
  | "CLICK_STOP_CARD"
  | "CLICK_STOP_PILL"
  | "CLICK_VIEW_CHANGE";

type ModeActionType = "CLICK_MODE_FILTER";

export interface ModeAction {
  type: ModeActionType;
  payload: {
    modes: TNMMode[];
  };
}

export interface StopAction {
  type: StopActionType;
  payload: {
    stopId: SelectedStopType;
  };
}

type Action = StopAction | ModeAction;

export const clickStopCardAction = (stopId: SelectedStopType): StopAction => ({
  type: "CLICK_STOP_CARD",
  payload: { stopId }
});

export const clickStopPillAction = (): StopAction => ({
  type: "CLICK_STOP_PILL",
  payload: { stopId: null }
});

export const clickViewChangeAction = (): StopAction => ({
  type: "CLICK_VIEW_CHANGE",
  payload: { stopId: null }
});

export const clickModeAction = (modes: TNMMode[]): ModeAction => ({
  type: "CLICK_MODE_FILTER",
  payload: { modes }
});

const stopReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "CLICK_CURRENT_LOCATION_MARKER":
    case "CLICK_MARKER": {
      const target =
        state.selectedStopId === action.payload.stopId
          ? null
          : action.payload.stopId;

      return {
        ...state,
        selectedStopId: target,
        shouldFilterStopCards: !!target && action.type === "CLICK_MARKER",
        shouldCenterMapOnSelectedStop: false
      };
    }
    case "CLICK_STOP_CARD":
      return {
        ...state,
        selectedStopId: action.payload.stopId,
        shouldFilterStopCards: state.shouldFilterStopCards,
        shouldCenterMapOnSelectedStop: true
      };
    case "CLICK_STOP_PILL":
      return {
        ...state,
        selectedStopId: null,
        shouldFilterStopCards: false,
        shouldCenterMapOnSelectedStop: false
      };
    case "CLICK_VIEW_CHANGE":
      return {
        ...state,
        selectedStopId: null,
        shouldFilterStopCards: false,
        shouldCenterMapOnSelectedStop: false,
        selectedModes: [],
        routesView: !state.routesView
      };
    default:
      return state;
  }
};

const modeReducer = (state: State, action: Action): State => {
  switch (action.type) {
    case "CLICK_MODE_FILTER":
      return {
        ...state,
        selectedModes: action.payload.modes,
        shouldFilterStopCards: true
      };
    default:
      return state;
  }
};

export const reducer = (state: State, action: Action): State =>
  [stopReducer, modeReducer].reduce(
    (accumulator, fn) => fn(accumulator, action),
    state
  );

export const initialState: State = {
  selectedStopId: null,
  shouldFilterStopCards: false,
  shouldCenterMapOnSelectedStop: false,
  routesView: true,
  selectedModes: []
};
