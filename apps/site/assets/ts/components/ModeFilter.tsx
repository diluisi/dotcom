import React, { ReactElement } from "react";
import { Mode } from "../__v3api";
import ModeIcon from "../tnm/components/ModeIcon";

type IsModeSelectedFunction = (mode: Mode) => boolean;

interface Props {
  isModeSelected: IsModeSelectedFunction;
  onModeClickAction: (mode: Mode) => void;
}

interface ModeButtonProps {
  mode: Mode;
  icon: string;
  name: string;
  isModeSelected: IsModeSelectedFunction;
  onClick: (mode: Mode) => () => void;
}

interface ModeByV3ModeType {
  [s: number]: Mode;
}

export const modeByV3ModeType: ModeByV3ModeType = {
  0: "subway",
  1: "subway",
  2: "commuter_rail",
  3: "bus"
};

const ModeButton = ({
  mode,
  icon,
  name,
  isModeSelected,
  onClick
}: ModeButtonProps): ReactElement<HTMLElement> => (
  <button
    className={`btn btn-secondary btn-sm m-tnm-sidebar__filter-btn ${
      isModeSelected(mode) ? "active" : "inactive"
    }`}
    onClick={onClick(mode)}
    type="button"
    aria-label={
      isModeSelected(mode)
        ? `remove filter by ${mode}`
        : `add filter by ${mode}`
    }
  >
    <ModeIcon type={icon} />
    {name}
  </button>
);

export const ModeFilter = ({
  isModeSelected,
  onModeClickAction
}: Props): ReactElement<HTMLElement> => (
  <div className="m-tnm-sidebar__filter-bar">
    <div className="m-tnm-sidebar__filter-bar-inner">
      <span className="m-tnm-sidebar__filter-header u-small-caps">Filter</span>
      <ModeButton
        mode="subway"
        icon="subway"
        name="Subway"
        isModeSelected={isModeSelected}
        onClick={mode => () => onModeClickAction(mode)}
      />
      <ModeButton
        mode="bus"
        icon="bus"
        name="Bus"
        isModeSelected={isModeSelected}
        onClick={mode => () => onModeClickAction(mode)}
      />
      <ModeButton
        mode="commuter_rail"
        icon="commuter_rail"
        name="Rail"
        isModeSelected={isModeSelected}
        onClick={mode => () => onModeClickAction(mode)}
      />
    </div>
  </div>
);
