// SPDX-License-Identifier: MIT
import { rawDefaults } from "./defaults.js";

export { rawDefaults } from "./defaults.js";
export const layoutIds = [
  "tile",
  "monocle",
  "threeColumn",
  "spiral",
  "quarter",
  "stacked",
  "columns",
  "spread",
  "floating",
  "stair",
  "binaryTree",
  "cascade",
] as const;
export type LayoutId = (typeof layoutIds)[number];
export type RawConfig = typeof rawDefaults;
const listKeys = [
  "ignoreClass",
  "ignoreTitle",
  "ignoreRole",
  "ignoreActivity",
  "ignoreScreen",
  "ignoreVDesktop",
  "tilingClass",
  "floatingClass",
  "floatingTitle",
  "screenDefaultLayout",
  "gapsOverrideConfig",
  "dockSurfacesConfig",
  "dockWindowClassConfig",
  "columnsLayerConf",
  "floatConfig",
  "shortcutConf",
  "soleWindowOutputOverride",
  "srfDefineCfg",
  "srfDefaultConfig",
] as const;
type ListKey = (typeof listKeys)[number];
export type Config = Omit<RawConfig, ListKey> & {
  readonly [K in ListKey]: readonly string[];
} & { readonly layoutOrder: readonly LayoutId[] };
/** The native KConfig reader has already decoded INI escapes, including newlines. */
export type ConfigReader = (
  key: string,
  defaultValue: string | number | boolean
) => unknown;
const newlinePattern = /\r?\n/;
const shortcutSuffixPattern = /sc$/;
const isStringList = (value: unknown): value is readonly string[] =>
  Array.isArray(value) &&
  value.every((entry: unknown) => typeof entry === "string");

function split(value: unknown, key: ListKey): readonly string[] {
  if (isStringList(value)) {
    return value
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0 && !entry.startsWith("#"));
  }
  if (typeof value !== "string") {
    return [];
  }
  const multiline = [
    "gapsOverrideConfig",
    "dockSurfacesConfig",
    "dockWindowClassConfig",
    "floatConfig",
    "shortcutConf",
    "soleWindowOutputOverride",
    "srfDefineCfg",
    "srfDefaultConfig",
  ].includes(key);
  return value
    .split(multiline ? newlinePattern : ",")
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0 && !entry.startsWith("#"));
}

/** Validate the untyped KConfig boundary, preserving all upstream configuration keys. */
function decodeScalar(
  input: unknown,
  baseline: string | number | boolean
): string | number | boolean {
  if (typeof baseline === "boolean") {
    if (typeof input === "boolean") {
      return input;
    }
    if (input === "true" || input === 1) {
      return true;
    }
    if (input === "false" || input === 0) {
      return false;
    }
    return baseline;
  }
  if (typeof baseline === "number") {
    let number = Number.NaN;
    if (typeof input === "number") {
      number = input;
    } else if (typeof input === "string" && input.trim()) {
      number = Number(input);
    }
    return Number.isFinite(number) ? number : baseline;
  }
  return typeof input === "string" ? input : baseline;
}
export function readConfig(reader: ConfigReader): Config {
  const values: Record<string, string | number | boolean | readonly string[]> =
    {};
  for (const [key, baseline] of Object.entries(rawDefaults)) {
    const input = reader(key, baseline);
    values[key] =
      listKeys.some((listKey) => listKey === key) && isStringList(input)
        ? input
        : decodeScalar(input, baseline);
  }
  for (const key of [
    "screenGapLeft",
    "screenGapRight",
    "screenGapTop",
    "screenGapBottom",
    "screenGapBetween",
  ]) {
    values[key] = Math.max(0, Number(values[key]));
  }
  for (const key of [
    "soleWindowWidth",
    "soleWindowHeight",
    "floatDefaultWidth",
    "floatDefaultHeight",
  ]) {
    values[key] = Math.min(100, Math.max(1, Number(values[key])));
  }
  if (values.monocleMinimizeRest) {
    values.preventMinimize = false;
  }
  const layoutOrder = layoutIds
    .map((id, index) => ({
      id,
      index,
      order: Number(values[`${id}LayoutOrder`]),
    }))
    .filter(
      ({ order }) =>
        Number.isInteger(order) && order > 0 && order <= layoutIds.length
    )
    .sort((left, right) => left.order - right.order || left.index - right.index)
    .map(({ id }) => id);
  return {
    ...rawDefaults,
    ...values,
    columnsLayerConf: split(values.columnsLayerConf, "columnsLayerConf"),
    dockSurfacesConfig: split(values.dockSurfacesConfig, "dockSurfacesConfig"),
    dockWindowClassConfig: split(
      values.dockWindowClassConfig,
      "dockWindowClassConfig"
    ),
    floatConfig: split(values.floatConfig, "floatConfig"),
    floatingClass: split(values.floatingClass, "floatingClass"),
    floatingTitle: split(values.floatingTitle, "floatingTitle"),
    gapsOverrideConfig: split(values.gapsOverrideConfig, "gapsOverrideConfig"),
    ignoreActivity: split(values.ignoreActivity, "ignoreActivity"),
    ignoreClass: split(values.ignoreClass, "ignoreClass"),
    ignoreRole: split(values.ignoreRole, "ignoreRole"),
    ignoreScreen: split(values.ignoreScreen, "ignoreScreen"),
    ignoreTitle: split(values.ignoreTitle, "ignoreTitle"),
    ignoreVDesktop: split(values.ignoreVDesktop, "ignoreVDesktop"),
    layoutOrder: layoutOrder.length ? layoutOrder : ["tile"],
    screenDefaultLayout: split(
      values.screenDefaultLayout,
      "screenDefaultLayout"
    ),
    shortcutConf: split(values.shortcutConf, "shortcutConf"),
    soleWindowOutputOverride: split(
      values.soleWindowOutputOverride,
      "soleWindowOutputOverride"
    ),
    srfDefaultConfig: split(values.srfDefaultConfig, "srfDefaultConfig"),
    srfDefineCfg: split(values.srfDefineCfg, "srfDefineCfg"),
    tilingClass: split(values.tilingClass, "tilingClass"),
  };
}
export const defaultConfig: Config = readConfig(
  (_key, defaultValue) => defaultValue
);

export type Action =
  | "focusNext"
  | "focusPrev"
  | "focusLeft"
  | "focusRight"
  | "focusUp"
  | "focusDown"
  | "moveLeft"
  | "moveRight"
  | "moveUp"
  | "moveDown"
  | "swapNext"
  | "swapPrev"
  | "growWidth"
  | "shrinkWidth"
  | "growHeight"
  | "shrinkHeight"
  | "increase"
  | "decrease"
  | "toggleFloat"
  | "floatAll"
  | "toggleDock"
  | "nextLayout"
  | "previousLayout"
  | "rotate"
  | "rotatePart"
  | "setMaster"
  | "dockLeft"
  | "dockRight"
  | "dockTop"
  | "dockBottom"
  | "capacityIncrease"
  | "capacityDecrease"
  | "capacityReset"
  | "alterRegister"
  | "toggleRegister"
  | `layout:${LayoutId}`;
export const shortcutActions: Readonly<Record<string, Action>> = {
  AlterRegisterSC: "alterRegister",
  DecreaseSC: "decrease",
  FocusDownSC: "focusDown",
  FocusLeftSC: "focusLeft",
  FocusNextSC: "focusNext",
  FocusPrevSC: "focusPrev",
  FocusRightSC: "focusRight",
  FocusUpSC: "focusUp",
  GrowHeightSC: "growHeight",
  GrowWidthSC: "growWidth",
  IncreaseSC: "increase",
  LowerSurfaceCapacitySC: "capacityDecrease",
  MoveDownSC: "moveDown",
  MoveLeftSC: "moveLeft",
  MoveRightSC: "moveRight",
  MoveUpSC: "moveUp",
  NextLayoutSC: "nextLayout",
  PreviousLayoutSC: "previousLayout",
  RaiseSurfaceCapacitySC: "capacityIncrease",
  RotatePartSC: "rotatePart",
  RotateSC: "rotate",
  SetBinaryTreeLayoutSC: "layout:binaryTree",
  SetCascadeLayoutSC: "layout:cascade",
  SetColumnsLayoutSC: "layout:columns",
  SetFloatingLayoutSC: "layout:floating",
  SetMasterSC: "setMaster",
  SetMonocleLayoutSC: "layout:monocle",
  SetQuarterLayoutSC: "layout:quarter",
  SetSpiralLayoutSC: "layout:spiral",
  SetSpreadLayoutSC: "layout:spread",
  SetStackedLayoutSC: "layout:stacked",
  SetStairLayoutSC: "layout:stair",
  SetThreeColumnLayoutSC: "layout:threeColumn",
  SetTileLayoutSC: "layout:tile",
  ShrinkHeightSC: "shrinkHeight",
  ShrinkWidthSC: "shrinkWidth",
  ToggleDockSC: "toggleDock",
  ToggleFloatAllSC: "floatAll",
  ToggleFloatSC: "toggleFloat",
};

export const layoutNames: Readonly<Record<LayoutId, string>> = {
  binaryTree: "Binary Tree",
  cascade: "Cascade",
  columns: "Columns",
  floating: "Floating",
  monocle: "Monocle",
  quarter: "Quarter",
  spiral: "Spiral",
  spread: "Spread",
  stacked: "Stacked",
  stair: "Stair",
  threeColumn: "Three Column",
  tile: "Tile",
};

export interface ShortcutRule {
  readonly action: Action | null;
  readonly registerAction: Action | null;
  readonly shortcuts: readonly string[];
  readonly timeout: number;
}
export function actionByName(input: string): Action | undefined {
  const normalized = input.trim().toLowerCase();
  const aliases: Readonly<Record<string, Action>> = {
    lowersurfacecapacity: "capacityDecrease",
    raisesurfacecapacity: "capacityIncrease",
    resetsurfacecapacity: "capacityReset",
    swapdown: "swapNext",
    swapup: "swapPrev",
    togglefloatall: "floatAll",
    toggleregister: "toggleRegister",
  };
  const known = aliases[normalized];
  if (known) {
    return known;
  }
  for (const action of Object.values(shortcutActions)) {
    if (action.toLowerCase() === normalized) {
      return action;
    }
  }
  const shortcut = Object.keys(shortcutActions).find(
    (key) => key.toLowerCase().replace(shortcutSuffixPattern, "") === normalized
  );
  return shortcut ? shortcutActions[shortcut] : undefined;
}
export function parseShortcutRules(config: Config): readonly ShortcutRule[] {
  const rules: ShortcutRule[] = [];
  for (const line of config.shortcutConf) {
    const separator = line.indexOf(":");
    if (separator < 0) {
      continue;
    }
    const names = line
      .slice(0, separator)
      .split(",")
      .map((entry) =>
        Object.keys(shortcutActions).find(
          (key) => key.toLowerCase() === entry.trim().toLowerCase()
        )
      );
    if (!names.length || names.some((entry) => entry === undefined)) {
      continue;
    }
    const shortcuts = names.filter(
      (entry): entry is string => entry !== undefined
    );
    const flags = Object.fromEntries(
      line
        .slice(separator + 1)
        .split(",")
        .map((entry) =>
          entry.split("=").map((part) => part.trim().toLowerCase())
        )
    );
    const main = flags.ma ?? flags.mainaction;
    const register = flags.ra ?? flags.registeraction;
    const timeout = Number(
      flags.st ?? flags.sequencetime ?? config.shortcutSequenceTime
    );
    const action = main ? actionByName(main) : null;
    const registerAction = register ? actionByName(register) : null;
    if (
      action === undefined ||
      registerAction === undefined ||
      (action === null && registerAction === null) ||
      !Number.isFinite(timeout) ||
      timeout < 0 ||
      timeout > 9999
    ) {
      continue;
    }
    rules.push({ action, registerAction, shortcuts, timeout });
  }
  if (config.altRegisterIsPushedTwice) {
    rules.push({
      action: "toggleRegister",
      registerAction: "toggleRegister",
      shortcuts: ["AlterRegisterSC", "AlterRegisterSC"],
      timeout: config.shortcutSequenceTime,
    });
  }
  return rules.map((rule) => ({
    ...rule,
    timeout: Math.max(
      ...rules
        .filter((entry) => entry.shortcuts[0] === rule.shortcuts[0])
        .map((entry) => entry.timeout)
    ),
  }));
}
