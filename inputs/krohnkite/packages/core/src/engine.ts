// biome-ignore-all lint/style/useAtIndex: Qt QV4 does not implement Array.prototype.at.
// SPDX-License-Identifier: MIT
import {
  type Action,
  type Config,
  defaultConfig,
  type LayoutId,
  layoutIds,
  layoutNames,
} from "@krohnkite/config";
import { dragWindow } from "./drag.js";
import {
  bottom,
  center,
  clamp,
  constrain,
  inset,
  right,
  sameRect,
} from "./geometry.js";
import { arrangeLayout } from "./layouts.js";
import {
  arrangeDocks,
  assignDockSlots,
  dockRule,
  dockValues,
  floatingRect,
  floatRule,
  getGaps,
  ignored,
  ignoredSurface,
  initialFloating,
  surfaceKey,
  surfaceMatches,
} from "./rules.js";
import { clearSequence, expireRegister, resolveShortcut } from "./shortcuts.js";
import type {
  Command,
  DockPosition,
  EngineEvent,
  EngineState,
  LayoutState,
  ManagedWindow,
  Rect,
  Surface,
  Transition,
} from "./types.js";
export function createState(config: Config = defaultConfig): EngineState {
  return {
    clock: 0,
    drag: null,
    focusId: null,
    layouts: {},
    register: false,
    registerEntered: null,
    registerMode: config.altRegisterIsToggle,
    shortcutDeadline: null,
    shortcutFallback: null,
    shortcutKeys: [],
    shortcutSurfaceId: null,
    shortcutTime: 0,
    surfaces: [],
    windows: [],
  };
}
const rotationIndex = (input: string): number => {
  const value = Number(input);
  if (value === 90 || value === 180 || value === 270) {
    return value / 90;
  }
  return Number.isInteger(value) && value >= 0 && value <= 3 ? value : 0;
};
const layoutSuffixPattern = /layout$/;

// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: Keep upstream layout selection and surface override precedence in one boundary.
function initialLayout(
  surface: Surface,
  config: Config,
  id?: LayoutId
): LayoutState {
  let selected = id ?? config.layoutOrder[0] ?? "tile";
  if (!id) {
    for (const line of config.screenDefaultLayout) {
      const parts = line.split(":").map((part) => part.trim());
      const screen = parts[0] ?? "";
      const desktop = parts.length > 2 ? (parts[parts.length - 2] ?? "") : "";
      const activity = parts.length > 3 ? (parts[1] ?? "") : "";
      if (
        (screen && screen !== surface.screen) ||
        (desktop && desktop !== (surface.desktopName ?? surface.desktop)) ||
        (activity && activity !== surface.activity)
      ) {
        continue;
      }
      const target = parts[parts.length - 1] ?? "";
      const numeric = Number(target);
      const found = Number.isInteger(numeric)
        ? config.layoutOrder[numeric]
        : layoutIds.find(
            (layout) =>
              layout.toLowerCase() ===
              target.toLowerCase().replace(layoutSuffixPattern, "")
          );
      if (found) {
        selected = found;
      }
      break;
    }
  }
  let columnWeights: number[] = [];
  for (const line of config.columnsLayerConf) {
    const parts = line.split(":").map((part) => part.trim());
    if (
      parts.length < 5 ||
      (parts[0] && parts[0] !== surface.screen) ||
      (parts[1] && parts[1] !== surface.activity) ||
      (parts[2] && parts[2] !== (surface.desktopName ?? surface.desktop))
    ) {
      continue;
    }
    const numbers = parts.slice(3).map(Number);
    if (numbers.every((number) => Number.isFinite(number) && number > 0)) {
      const sum = numbers.reduce((total, weight) => total + weight, 0);
      columnWeights = numbers.map((weight) => (weight * numbers.length) / sum);
    }
    break;
  }
  let rotation = 0;
  if (selected === "columns") {
    rotation = rotationIndex(config.columnsLayoutInitialRotationAngle);
  }
  if (selected === "tile") {
    rotation = rotationIndex(config.tileLayoutInitialRotationAngle);
  }
  return {
    capacity: null,
    cascade: 4,
    columns: {},
    columnWeights,
    id: selected,
    masterCount: 1,
    masterRotation: 0,
    previousCount: 0,
    previousId: selected,
    previousMasterId: null,
    quarterLeft: 0.5,
    quarterRight: 0.5,
    ratio: selected === "threeColumn" ? 0.6 : 0.5,
    rotation,
    spread: clamp(config.spreadLayoutSpace / 100, 0.01, 0.5),
    stair: 24,
  };
}
const visible = (window: ManagedWindow, config: Config): boolean =>
  window.visible !== false &&
  !(window.minimized && !window.layoutMinimized && !config.preventMinimize) &&
  !window.fullScreen &&
  !(window.maximized && !window.layoutMaximized);
function windowsOn(
  state: EngineState,
  surface: Surface,
  config: Config,
  includeInactive = false
): ManagedWindow[] {
  return state.windows.filter(
    (window) =>
      window.surfaceId === surface.id &&
      !ignored(window, config) &&
      (includeInactive ? !window.fullScreen : visible(window, config))
  );
}

function surfacePolicy(
  surface: Surface,
  config: Config
): { readonly capacity: number | null; readonly overflow: boolean } {
  let capacity: number | null = null;
  let overflow = true;
  const line = config.srfDefaultConfig.find((entry) =>
    surfaceMatches(surface, entry.split(":")[0] ?? "", config)
  );
  for (const field of line?.slice((line.indexOf(":") ?? -1) + 1).split(",") ??
    []) {
    const [key, value] = field
      .split("=")
      .map((part) => part.trim().toLowerCase());
    if (
      (key === "cp" || key === "capacity") &&
      value &&
      Number.isFinite(Number(value))
    ) {
      capacity = clamp(Number(value), 1, 99);
    }
    if (key === "oc" || key === "overcapacity") {
      overflow = value !== "false" && value !== "disable";
    }
  }
  return { capacity, overflow };
}
function capacityFor(
  surface: Surface,
  layout: LayoutState,
  config: Config
): number | null {
  let configured = 0;
  if (layout.id === "quarter") {
    configured = 4;
  } else if (layout.id !== "monocle" && layout.id !== "floating") {
    configured = config[`${layout.id}LayoutCapacity`];
  }
  const policy = surfacePolicy(surface, config);
  if (layout.capacity !== null) {
    return layout.capacity;
  }
  if (configured <= 0) {
    return policy.capacity;
  }
  return policy.capacity === null
    ? configured
    : Math.min(configured, policy.capacity);
}
function nextSurface(
  state: EngineState,
  surface: Surface,
  direction: string,
  config: Config
): Surface | undefined {
  const origin = center(surface.area);
  const horizontal = direction === "left" || direction === "right";
  const sign = direction === "left" || direction === "up" ? -1 : 1;
  return state.surfaces
    .filter(
      (target) =>
        target.id !== surface.id &&
        target.active !== false &&
        !ignoredSurface(target, config)
    )
    .map((target) => {
      const point = center(target.area);
      return {
        delta:
          ((horizontal ? point.x : point.y) -
            (horizontal ? origin.x : origin.y)) *
          sign,
        secondary: Math.abs(
          (horizontal ? point.y : point.x) - (horizontal ? origin.y : origin.x)
        ),
        target,
      };
    })
    .filter(({ delta }) => delta > 0)
    .sort(
      (leftTarget, rightTarget) =>
        leftTarget.delta +
        leftTarget.secondary -
        rightTarget.delta -
        rightTarget.secondary
    )[0]?.target;
}
function neighbor(
  windows: readonly ManagedWindow[],
  basis: ManagedWindow,
  direction: string
): ManagedWindow | undefined {
  const origin = center(basis.geometry);
  const horizontal = direction === "left" || direction === "right";
  const sign = direction === "left" || direction === "up" ? -1 : 1;
  return windows
    .filter((window) => window.id !== basis.id)
    .map((window) => {
      const point = center(window.geometry);
      const main =
        ((horizontal ? point.x : point.y) -
          (horizontal ? origin.x : origin.y)) *
        sign;
      const secondary = Math.abs(
        (horizontal ? point.y : point.x) - (horizontal ? origin.y : origin.x)
      );
      const overlap = horizontal
        ? window.geometry.y < bottom(basis.geometry) &&
          bottom(window.geometry) > basis.geometry.y
        : window.geometry.x < right(basis.geometry) &&
          right(window.geometry) > basis.geometry.x;
      return { main, score: main + secondary * (overlap ? 0.2 : 2), window };
    })
    .filter(({ main }) => main > 0)
    .sort(
      (leftCandidate, rightCandidate) =>
        leftCandidate.score - rightCandidate.score ||
        (rightCandidate.window.focusTime ?? 0) -
          (leftCandidate.window.focusTime ?? 0)
    )[0]?.window;
}
function replaceWindow(
  state: EngineState,
  id: string,
  update: (window: ManagedWindow) => ManagedWindow
): EngineState {
  return {
    ...state,
    windows: state.windows.map((window) =>
      window.id === id ? update(window) : window
    ),
  };
}
function changeLayout(
  state: EngineState,
  surface: Surface,
  layout: LayoutState,
  config: Config
): EngineState {
  return {
    ...state,
    layouts: { ...state.layouts, [surfaceKey(surface, config)]: layout },
  };
}
function swap(state: EngineState, first: string, second: string): EngineState {
  const firstIndex = state.windows.findIndex((window) => window.id === first);
  const secondIndex = state.windows.findIndex((window) => window.id === second);
  if (firstIndex < 0 || secondIndex < 0) {
    return state;
  }
  const windows = [...state.windows];
  const leftWindow = windows[firstIndex];
  const rightWindow = windows[secondIndex];
  if (!(leftWindow && rightWindow)) {
    return state;
  }
  windows[firstIndex] = rightWindow;
  windows[secondIndex] = leftWindow;
  return { ...state, windows };
}
const dockActionPositions: Partial<Readonly<Record<Action, DockPosition>>> = {
  dockBottom: "bottom",
  dockLeft: "left",
  dockRight: "right",
  dockTop: "top",
};
function directionStep(
  direction: string,
  negative: string,
  positive: string
): number {
  if (direction === negative) {
    return -1;
  }
  return direction === positive ? 1 : 0;
}
// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: This explicit dispatcher keeps all upstream shortcut families and their commands auditable together.
function action(
  initialState: EngineState,
  input: Extract<EngineEvent, { type: "action" }>,
  config: Config,
  resolved = false
): Transition {
  let state = initialState;
  const commands: Command[] = [];
  const current = state.windows.find((window) => window.id === state.focusId);
  const surface =
    state.surfaces.find(
      (entry) => entry.id === (input.surfaceId ?? current?.surfaceId)
    ) ?? state.surfaces[0];
  if (!surface) {
    return { commands, state };
  }
  const key = surfaceKey(surface, config);
  const layout = state.layouts[key] ?? initialLayout(surface, config);
  const windows = windowsOn(state, surface, config);
  const tiles = windows.filter((window) => !(window.floating || window.docked));
  const index = windows.findIndex((window) => window.id === state.focusId);
  let name: Action = input.action;
  const time = input.time ?? state.clock;
  if (!resolved) {
    const result = resolveShortcut(state, input, config);
    ({ state } = result);
    commands.push(...result.commands);
    if (result.name === null) {
      return { commands, state };
    }
    ({ name } = result);
  }
  if (name === "alterRegister" || name === "toggleRegister") {
    const registerMode =
      name === "toggleRegister" ? !state.registerMode : state.registerMode;
    const register = name === "toggleRegister" ? registerMode : !state.register;
    if (register !== registerMode) {
      commands.push({
        deadline: time + config.altRegisterTimeout,
        type: "shortcutTimer",
      });
    }
    return {
      commands: [
        ...commands,
        {
          message: register ? "Alternate shortcuts" : "Normal shortcuts",
          type: "notify",
        },
      ],
      state: {
        ...state,
        register,
        registerEntered: register === registerMode ? null : time,
        registerMode,
      },
    };
  }
  if (layout.id === "monocle" && name.startsWith("focus")) {
    const step =
      name === "focusNext" || name === "focusLeft" || name === "focusUp"
        ? -1
        : 1;
    const target =
      windows[(index + step + windows.length) % windows.length] ?? windows[0];
    return target
      ? {
          commands: [{ id: target.id, type: "focus" }],
          state: { ...state, focusId: target.id },
        }
      : { commands, state };
  }
  if (name === "focusNext" || name === "focusPrev") {
    const target =
      windows[
        (index + (name === "focusNext" ? 1 : -1) + windows.length) %
          windows.length
      ] ?? windows[0];
    if (target) {
      return {
        commands: [{ id: target.id, type: "focus" }],
        state: { ...state, focusId: target.id },
      };
    }
    return { commands, state };
  }
  if (name.startsWith("focus")) {
    const direction = name.slice(5).toLowerCase();
    let target = current ? neighbor(windows, current, direction) : windows[0];
    if (
      !target &&
      (state.register
        ? config.focusMoveScreensMeta
        : config.focusMoveScreensNormal)
    ) {
      const surfaceTarget = nextSurface(state, surface, direction, config);
      if (surfaceTarget) {
        [target] = windowsOn(state, surfaceTarget, config).sort(
          (leftWindow, rightWindow) =>
            (rightWindow.focusTime ?? 0) - (leftWindow.focusTime ?? 0)
        );
      }
    }
    return target
      ? {
          commands: [{ id: target.id, type: "focus" }],
          state: { ...state, focusId: target.id },
        }
      : { commands, state };
  }
  if (
    name === "nextLayout" ||
    name === "previousLayout" ||
    name.startsWith("layout:")
  ) {
    const targetIndex =
      (config.layoutOrder.indexOf(layout.id) +
        (name === "previousLayout" ? -1 : 1) +
        config.layoutOrder.length) %
      config.layoutOrder.length;
    let id = name.startsWith("layout:")
      ? (layoutIds.find((layoutId) => `layout:${layoutId}` === name) ??
        layout.id)
      : (config.layoutOrder[targetIndex] ?? "tile");
    if (id === "monocle" && layout.id === "monocle") {
      id = layout.previousId;
    }
    const restored =
      state.layouts[`${key}@${id}`] ?? initialLayout(surface, config, id);
    state = {
      ...state,
      layouts: {
        ...state.layouts,
        [`${key}@${layout.id}`]: layout,
        [key]: { ...restored, previousId: layout.id },
      },
    };
    return { commands: [{ message: layoutNames[id], type: "notify" }], state };
  }
  if (name === "floatAll") {
    const float = !windows.some((window) => window.floating);
    const ids = new Set(windows.map((window) => window.id));
    state = {
      ...state,
      windows: state.windows.map((window) =>
        ids.has(window.id)
          ? {
              ...window,
              docked: false,
              floating: float,
              floatingGeometry: window.floatingGeometry ?? window.geometry,
              manualDocked: false,
              manualFloating: float,
            }
          : window
      ),
    };
    return {
      commands: [{ message: float ? "Float All" : "Tile All", type: "notify" }],
      state,
    };
  }
  if (
    name === "increase" ||
    name === "decrease" ||
    name === "rotate" ||
    name === "rotatePart" ||
    name.startsWith("capacity")
  ) {
    const step = name === "decrease" || name === "capacityDecrease" ? -1 : 1;
    let updated = layout;
    if (name === "rotate") {
      updated = { ...layout, rotation: (layout.rotation + 1) % 4 };
    } else if (name === "rotatePart") {
      updated =
        layout.id === "columns"
          ? { ...layout, rotation: (layout.rotation + 3) % 4 }
          : { ...layout, masterRotation: (layout.masterRotation + 1) % 4 };
    } else if (name.startsWith("capacity")) {
      updated = {
        ...layout,
        capacity:
          name === "capacityReset"
            ? null
            : clamp((layout.capacity ?? tiles.length) + step, 0, 98),
      };
    } else if (layout.id === "spread") {
      updated = {
        ...layout,
        spread: clamp(layout.spread + step * 0.01, 0.04, 0.1),
      };
    } else if (layout.id === "stair") {
      updated = { ...layout, stair: clamp(layout.stair + step * 8, 16, 160) };
    } else if (layout.id === "cascade") {
      updated = { ...layout, cascade: (layout.cascade + step + 8) % 8 };
    } else {
      updated = {
        ...layout,
        masterCount: clamp(
          layout.masterCount + step,
          layout.id === "threeColumn" ? 1 : 0,
          10
        ),
      };
    }
    return {
      commands: [
        {
          message: `${layoutNames[layout.id]} [${updated.capacity ?? updated.masterCount}]`,
          type: "notify",
        },
      ],
      state: changeLayout(state, surface, updated, config),
    };
  }
  if (!current) {
    return { commands, state };
  }
  if (name === "toggleFloat") {
    return {
      commands,
      state: replaceWindow(state, current.id, (window) => ({
        ...window,
        docked: false,
        floating: !window.floating,
        floatingGeometry: window.floatingGeometry ?? window.geometry,
        manualDocked: false,
        manualFloating: !window.floating,
      })),
    };
  }
  if (name === "toggleDock" || name.startsWith("dock")) {
    return {
      commands,
      state: replaceWindow(state, current.id, (window) => ({
        ...window,
        docked: name === "toggleDock" ? !window.docked : true,
        dockPosition:
          dockActionPositions[name] ?? window.dockPosition ?? "left",
        floating: false,
        manualDocked: name === "toggleDock" ? !window.docked : true,
        manualFloating: false,
      })),
    };
  }
  if (name === "setMaster") {
    const [master] = tiles;
    if (!master) {
      return { commands, state };
    }
    const target =
      master.id === current.id
        ? (tiles.find((window) => window.id === layout.previousMasterId) ??
          tiles[1])
        : current;
    if (target) {
      state = swap(state, master.id, target.id);
      state = changeLayout(
        state,
        surface,
        { ...layout, previousMasterId: master.id },
        config
      );
      state = { ...state, focusId: target.id };
      commands.push({ id: target.id, type: "focus" });
    }
    return { commands, state };
  }
  if (name === "swapNext" || name === "swapPrev") {
    const target =
      windows[
        (index + (name === "swapNext" ? 1 : -1) + windows.length) %
          windows.length
      ];
    return {
      commands,
      state: target ? swap(state, current.id, target.id) : state,
    };
  }
  if (name.startsWith("move")) {
    const direction = name.slice(4).toLowerCase();
    if (current.docked) {
      const positions: Readonly<Record<string, DockPosition>> = {
        bottom: "bottom",
        left: "left",
        right: "right",
        top: "top",
      };
      const position = positions[direction];
      const occupied = windows.some(
        (window) =>
          window.docked &&
          window.id !== current.id &&
          window.dockPosition === position
      );
      return {
        commands,
        state:
          position && !occupied
            ? replaceWindow(state, current.id, (window) => ({
                ...window,
                dockPosition: position,
                manualDocked: true,
              }))
            : state,
      };
    }
    if (current.floating) {
      const rule = floatRule(current, config);
      const x =
        current.geometry.x +
        (directionStep(direction, "left", "right") *
          surface.area.width *
          (rule?.stepWidth ?? config.floatSizeStepWidth)) /
          100;
      const y =
        current.geometry.y +
        (directionStep(direction, "up", "down") *
          surface.area.height *
          (rule?.stepHeight ?? config.floatSizeStepHeight)) /
          100;
      const geometry = constrain({ ...current.geometry, x, y }, surface.area);
      return {
        commands: [{ geometry, id: current.id, type: "geometry" }],
        state: replaceWindow(state, current.id, (window) => ({
          ...window,
          floatingGeometry: geometry,
          geometry,
        })),
      };
    }
    if (layout.id === "columns") {
      const horizontal = layout.rotation % 2 === 1;
      const cross = horizontal
        ? direction === "left" || direction === "right"
        : direction === "up" || direction === "down";
      if (cross) {
        let step = direction === "left" || direction === "up" ? -1 : 1;
        if (layout.rotation === 1 || layout.rotation === 2) {
          step *= -1;
        }
        const column = layout.columns[current.id] ?? 0;
        const target = Math.max(0, column + step);
        const shifted =
          column === 0 && step === -1
            ? Object.fromEntries(
                Object.entries(layout.columns).map(([id, value]) => [
                  id,
                  value + 1,
                ])
              )
            : layout.columns;
        return {
          commands,
          state: changeLayout(
            state,
            surface,
            { ...layout, columns: { ...shifted, [current.id]: target } },
            config
          ),
        };
      }
    }
    const target = neighbor(tiles, current, direction);
    if (target) {
      return { commands, state: swap(state, current.id, target.id) };
    }
    if (
      state.register
        ? config.focusMoveScreensMeta
        : config.focusMoveScreensNormal
    ) {
      const surfaceTarget = nextSurface(state, surface, direction, config);
      if (surfaceTarget) {
        return {
          commands: [
            { id: current.id, surfaceId: surfaceTarget.id, type: "surface" },
          ],
          state: replaceWindow(state, current.id, (window) => ({
            ...window,
            surfaceId: surfaceTarget.id,
          })),
        };
      }
    }
    return { commands, state };
  }
  if (
    name === "growWidth" ||
    name === "shrinkWidth" ||
    name === "growHeight" ||
    name === "shrinkHeight"
  ) {
    const horizontal = name.endsWith("Width");
    const sign = name.startsWith("grow") ? 1 : -1;
    if (current.docked) {
      const verticalDock =
        current.dockPosition === "left" || current.dockPosition === "right";
      const field = `${verticalDock ? "v" : "h"}${horizontal ? "w" : "h"}`;
      const defaults: Readonly<Record<string, number>> = {
        hh: config.dockHHeight,
        hw: config.dockHWide,
        vh: config.dockVHeight,
        vw: config.dockVWide,
      };
      const values = dockValues(surface, current, config);
      const previous = Number(values[field] ?? defaults[field]);
      const value = clamp(
        (Number.isFinite(previous) ? previous : 15) + sign,
        1,
        horizontal === verticalDock ? 50 : 100
      );
      return {
        commands,
        state: replaceWindow(state, current.id, (window) => ({
          ...window,
          dockOverrides: { ...window.dockOverrides, [field]: String(value) },
        })),
      };
    }
    if (current.floating) {
      const geometry = constrain(
        {
          ...current.geometry,
          height:
            current.geometry.height +
            (horizontal
              ? 0
              : (sign * surface.area.height * config.floatSizeStepHeight) /
                100),
          width:
            current.geometry.width +
            (horizontal
              ? (sign * surface.area.width * config.floatSizeStepWidth) / 100
              : 0),
        },
        surface.area
      );
      return {
        commands: [{ geometry, id: current.id, type: "geometry" }],
        state: replaceWindow(state, current.id, (window) => ({
          ...window,
          floatingGeometry: geometry,
          geometry,
        })),
      };
    }
    if (layout.id === "columns" && horizontal === (layout.rotation % 2 === 1)) {
      const column = layout.columns[current.id] ?? 0;
      const columnWeights = [...layout.columnWeights];
      columnWeights[column] = clamp(
        (columnWeights[column] ?? 1) + sign * 0.1,
        0.1,
        10
      );
      return {
        commands,
        state: changeLayout(
          state,
          surface,
          { ...layout, columnWeights },
          config
        ),
      };
    }
    if (horizontal !== (layout.rotation % 2 === 1)) {
      return {
        commands,
        state: changeLayout(
          state,
          surface,
          {
            ...layout,
            ratio: clamp(
              layout.ratio +
                sign *
                  0.05 *
                  (tiles.indexOf(current) < layout.masterCount ? 1 : -1),
              0.2,
              0.8
            ),
          },
          config
        ),
      };
    }
    return {
      commands,
      state: replaceWindow(state, current.id, (window) => ({
        ...window,
        weight: clamp((window.weight ?? 1) + sign * 0.1, 0.1, 10),
      })),
    };
  }
  return { commands, state };
}

// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: Resize deltas follow different axes for Quarter, Columns and master layouts.
function adjustResize(
  initialState: EngineState,
  id: string,
  geometry: Rect,
  config: Config
): EngineState {
  let state = initialState;
  const window = state.windows.find((entry) => entry.id === id);
  const surface = state.surfaces.find(
    (entry) => entry.id === window?.surfaceId
  );
  if (!(window && surface)) {
    return state;
  }
  if (window.floating) {
    return replaceWindow(state, id, (entry) => ({
      ...entry,
      floatingGeometry: geometry,
      geometry,
    }));
  }
  if (window.docked) {
    const vertical =
      window.dockPosition === "left" || window.dockPosition === "right";
    const defaults: Readonly<Record<string, number>> = {
      hh: config.dockHHeight,
      hw: config.dockHWide,
      vh: config.dockVHeight,
      vw: config.dockVWide,
    };
    const values = dockValues(surface, window, config);
    const widthField = vertical ? "vw" : "hw";
    const heightField = vertical ? "vh" : "hh";
    return replaceWindow(state, id, (entry) => ({
      ...entry,
      dockOverrides: {
        ...entry.dockOverrides,
        [widthField]: String(
          clamp(
            Number(values[widthField] ?? defaults[widthField]) +
              (100 * (geometry.width - window.geometry.width)) /
                surface.area.width,
            1,
            vertical ? 50 : 100
          )
        ),
        [heightField]: String(
          clamp(
            Number(values[heightField] ?? defaults[heightField]) +
              (100 * (geometry.height - window.geometry.height)) /
                surface.area.height,
            1,
            vertical ? 100 : 50
          )
        ),
      },
    }));
  }
  if (!config.adjustLayout) {
    return state;
  }
  const key = surfaceKey(surface, config);
  const layout = state.layouts[key] ?? initialLayout(surface, config);
  const dx = geometry.width - window.geometry.width;
  const dy = geometry.height - window.geometry.height;
  if (layout.id === "columns") {
    const horizontal = layout.rotation % 2 === 1;
    const column = layout.columns[id] ?? 0;
    const columnWeights = [...layout.columnWeights];
    const delta = horizontal
      ? dx / Math.max(1, window.geometry.width)
      : dy / Math.max(1, window.geometry.height);
    columnWeights[column] = clamp(
      (columnWeights[column] ?? 1) * (1 + delta),
      0.1,
      10
    );
    state = changeLayout(state, surface, { ...layout, columnWeights }, config);
    const memberDelta = horizontal
      ? dy / Math.max(1, window.geometry.height)
      : dx / Math.max(1, window.geometry.width);
    return replaceWindow(state, id, (entry) => ({
      ...entry,
      weight: clamp((entry.weight ?? 1) * (1 + memberDelta), 0.1, 10),
    }));
  }
  if (layout.id === "quarter") {
    const index = windowsOn(state, surface, config)
      .filter((entry) => !(entry.floating || entry.docked))
      .findIndex((entry) => entry.id === id);
    const east = index === 0 || index === 3;
    return changeLayout(
      state,
      surface,
      {
        ...layout,
        quarterLeft: east
          ? clamp(
              layout.quarterLeft +
                (index === 0 ? dy : -dy) / surface.area.height,
              0.2,
              0.8
            )
          : layout.quarterLeft,
        quarterRight: east
          ? layout.quarterRight
          : clamp(
              layout.quarterRight +
                (index === 1 ? dy : -dy) / surface.area.height,
              0.2,
              0.8
            ),
        ratio: clamp(
          layout.ratio + (east ? dx : -dx) / surface.area.width,
          0.2,
          0.8
        ),
      },
      config
    );
  }
  const tiles = windowsOn(state, surface, config).filter(
    (entry) => !(entry.floating || entry.docked)
  );
  const primary =
    tiles.findIndex((entry) => entry.id === id) < layout.masterCount;
  const delta =
    layout.rotation % 2 === 0
      ? dx / surface.area.width
      : dy / surface.area.height;
  state = changeLayout(
    state,
    surface,
    {
      ...layout,
      ratio: clamp(layout.ratio + delta * (primary ? 1 : -1), 0.2, 0.8),
    },
    config
  );
  const weightDelta =
    layout.rotation % 2 === 0
      ? dy / Math.max(1, window.geometry.height)
      : dx / Math.max(1, window.geometry.width);
  return replaceWindow(state, id, (entry) => ({
    ...entry,
    weight: clamp((entry.weight ?? 1) * (1 + weightDelta), 0.1, 10),
  }));
}

// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: The transaction combines relocation, layout and restoration policies before emitting side effects.
function arrange(initialState: EngineState, config: Config): Transition {
  let state = initialState;
  const commands: Command[] = [];
  state = {
    ...state,
    windows: state.windows.map((window) => {
      const dock = dockRule(window, config);
      return {
        ...window,
        docked: window.manualDocked ?? dock?.auto ?? false,
        dockPosition: window.manualDocked
          ? (window.dockPosition ?? "left")
          : (dock?.position ?? window.dockPosition ?? "left"),
        floating: window.manualFloating ?? initialFloating(window, config),
      };
    }),
  };
  for (const surface of state.surfaces) {
    if (surface.active === false || ignoredSurface(surface, config)) {
      continue;
    }
    const assigned = new Map(
      assignDockSlots(windowsOn(state, surface, config), config).map(
        (window) => [window.id, window]
      )
    );
    state = {
      ...state,
      windows: state.windows.map((window) => assigned.get(window.id) ?? window),
    };
  }
  // Relocate before laying out any surface so output ordering cannot leave stale geometry.
  if (config.srfExceededToScreen || config.srfExceededToVDesktop) {
    for (const surface of state.surfaces) {
      if (surface.active === false || ignoredSurface(surface, config)) {
        continue;
      }
      const layout =
        state.layouts[surfaceKey(surface, config)] ??
        initialLayout(surface, config);
      const tiles = windowsOn(state, surface, config).filter(
        (window) => !(window.floating || window.docked)
      );
      const capacity = capacityFor(surface, layout, config);
      if (capacity === null || tiles.length <= capacity) {
        continue;
      }
      const overflow = config.srfIsMoveOldestWindows
        ? tiles.slice(0, tiles.length - capacity)
        : tiles.slice(capacity);
      for (const window of overflow) {
        const target = state.surfaces.find((entry) => {
          if (
            entry.id === surface.id ||
            ignoredSurface(entry, config) ||
            !surfacePolicy(entry, config).overflow
          ) {
            return false;
          }
          if (
            entry.screen === surface.screen
              ? !config.srfExceededToVDesktop
              : !config.srfExceededToScreen
          ) {
            return false;
          }
          const targetLayout =
            state.layouts[surfaceKey(entry, config)] ??
            initialLayout(entry, config);
          const targetCapacity = capacityFor(entry, targetLayout, config);
          return (
            targetCapacity === null ||
            windowsOn(state, entry, config, true).filter(
              (member) => !(member.floating || member.docked)
            ).length < targetCapacity
          );
        });
        if (!target) {
          continue;
        }
        state = replaceWindow(state, window.id, (entry) => ({
          ...entry,
          surfaceId: target.id,
          visible: target.active !== false,
        }));
        commands.push({ id: window.id, surfaceId: target.id, type: "surface" });
      }
    }
  }
  for (const surface of state.surfaces) {
    if (surface.active === false || ignoredSurface(surface, config)) {
      continue;
    }
    const key = surfaceKey(surface, config);
    let layout = state.layouts[key] ?? initialLayout(surface, config);
    const members = windowsOn(state, surface, config);
    const docking = arrangeDocks(surface, members, config);
    const gaps = getGaps(surface, config);
    let area = inset(
      docking.area,
      gaps.left,
      gaps.top,
      gaps.right,
      gaps.bottom
    );
    let tiles = members.filter((window) => !(window.floating || window.docked));
    if (
      config.quarterLayoutReset &&
      layout.id === "quarter" &&
      tiles.length < layout.previousCount
    ) {
      layout = { ...layout, quarterLeft: 0.5, quarterRight: 0.5, ratio: 0.5 };
    }
    const capacity = capacityFor(surface, layout, config);
    if (capacity !== null) {
      tiles = tiles.slice(0, capacity);
    }
    if (layout.id === "columns") {
      const columns = { ...layout.columns };
      const initialCount = Math.max(1, layout.columnWeights.length);
      for (const window of tiles) {
        if (columns[window.id] === undefined) {
          const assigned = tiles.filter(
            (entry) => columns[entry.id] !== undefined
          );
          const counts = Array.from(
            { length: initialCount },
            (_entry, columnIndex) =>
              assigned.filter((entry) => columns[entry.id] === columnIndex)
                .length
          );
          const missing = counts.indexOf(0);
          let column = state.focusId ? (columns[state.focusId] ?? 0) : 0;
          if (missing >= 0) {
            column = missing;
          } else if (config.columnsBalanced) {
            column = counts.indexOf(Math.min(...counts));
          }
          columns[window.id] = column;
        }
      }
      layout = { ...layout, columns };
    }
    layout = { ...layout, previousCount: tiles.length };
    state = changeLayout(state, surface, layout, config);
    if (tiles.length === 1 && layout.id !== "floating") {
      const base = config.soleWindowNoGaps ? docking.area : area;
      const width = (base.width * config.soleWindowWidth) / 100;
      const height = (base.height * config.soleWindowHeight) / 100;
      area = {
        height,
        width,
        x: base.x + (base.width - width) / 2,
        y: base.y + (base.height - height) / 2,
      };
    }
    const geometries = arrangeLayout(area, tiles, layout, config, gaps.between);
    const assignments = new Map(
      tiles.map((window, index) => [window.id, geometries[index]])
    );
    for (const window of members) {
      const tiled = assignments.has(window.id) && layout.id !== "floating";
      let geometry =
        docking.geometries.get(window.id) ??
        assignments.get(window.id) ??
        (window.floating || layout.id === "floating"
          ? (window.floatingGeometry ?? floatingRect(window, surface, config))
          : window.geometry);
      if (
        config.limitTileWidth &&
        tiled &&
        geometry.width > surface.area.height * config.limitTileWidthRatio
      ) {
        const width = Math.max(
          1,
          surface.area.height * config.limitTileWidthRatio
        );
        geometry = {
          ...geometry,
          width,
          x: geometry.x + (geometry.width - width) / 2,
        };
      }
      if (window.minSize) {
        geometry = {
          ...geometry,
          height: Math.max(geometry.height, window.minSize.height),
          width: Math.max(geometry.width, window.minSize.width),
        };
      }
      if (window.maxSize) {
        geometry = {
          ...geometry,
          height: Math.min(
            geometry.height,
            window.maxSize.height || geometry.height
          ),
          width: Math.min(
            geometry.width,
            window.maxSize.width || geometry.width
          ),
        };
      }
      if (config.preventProtrusion) {
        geometry = constrain(geometry, surface.area);
      }
      const maximized =
        tiled && layout.id === "monocle" && config.monocleMaximize;
      const minimized =
        tiled &&
        layout.id === "monocle" &&
        config.monocleMinimizeRest &&
        window.id !== state.focusId;
      if (maximized !== Boolean(window.layoutMaximized)) {
        commands.push({ id: window.id, maximized, type: "maximize" });
      }
      if (
        minimized !== Boolean(window.layoutMinimized) ||
        (config.preventMinimize && window.minimized)
      ) {
        commands.push({ id: window.id, minimized, type: "minimize" });
      }
      if (
        state.drag?.id !== window.id &&
        !sameRect(window.geometry, geometry)
      ) {
        commands.push({ geometry, id: window.id, type: "geometry" });
      }
      commands.push({
        id: window.id,
        noBorder:
          tiled &&
          (config.noTileBorder ||
            (tiles.length === 1 && config.soleWindowNoBorders)),
        type: "border",
      });
      commands.push({
        id: window.id,
        layer: tiled ? config.tiledWindowsLayer : config.floatedWindowsLayer,
        type: "layer",
      });
      state = replaceWindow(state, window.id, (entry) => ({
        ...entry,
        geometry,
        layoutMaximized: maximized,
        layoutMinimized: minimized,
      }));
    }
  }
  return { commands, state };
}

/** The reducer is deterministic: KWin side effects are explicit commands. */
// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: Explicit event branches preserve immutable state before one arrangement transaction.
export function reduce(
  initialState: EngineState,
  event: EngineEvent,
  config: Config = defaultConfig
): Transition {
  let state = initialState;
  let commands: readonly Command[] = [];
  switch (event.type) {
    case "surfaces":
      state = { ...state, surfaces: [...event.surfaces] };
      break;
    case "upsert": {
      const previous = state.windows.find(
        (window) => window.id === event.window.id
      );
      if (previous) {
        state = replaceWindow(state, previous.id, (window) => ({
          ...window,
          ...event.window,
        }));
      } else {
        const dock = dockRule(event.window, config);
        const surface = state.surfaces.find(
          (entry) => entry.id === event.window.surfaceId
        );
        const window: ManagedWindow = {
          ...event.window,
          ...(event.window.floating === undefined
            ? {}
            : { manualFloating: event.window.floating }),
          ...(event.window.docked === undefined
            ? {}
            : { manualDocked: event.window.docked }),
          docked: event.window.docked ?? dock?.auto ?? false,
          dockPosition: event.window.dockPosition ?? dock?.position ?? "left",
          floating:
            event.window.floating ?? initialFloating(event.window, config),
          floatingGeometry: surface
            ? floatingRect(event.window, surface, config)
            : event.window.geometry,
        };
        const windows = [...state.windows];
        if (config.newWindowPosition === 1) {
          windows.unshift(window);
        } else if (config.newWindowPosition === 2) {
          const first = windows.findIndex(
            (entry) => entry.surfaceId === window.surfaceId
          );
          windows.splice(first >= 0 ? first + 1 : windows.length, 0, window);
        } else {
          windows.push(window);
        }
        state = { ...state, windows };
      }
      break;
    }
    case "remove":
      state = {
        ...state,
        drag: state.drag?.id === event.id ? null : state.drag,
        focusId: state.focusId === event.id ? null : state.focusId,
        windows: state.windows.filter((window) => window.id !== event.id),
      };
      break;
    case "focus":
      state = { ...state, clock: state.clock + 1, focusId: event.id };
      if (event.id) {
        state = replaceWindow(state, event.id, (window) => ({
          ...window,
          focusTime: state.clock,
        }));
      }
      break;
    case "action": {
      const transition = action(state, event, config);
      ({ state, commands } = transition);
      break;
    }
    case "shortcutTimeout": {
      const expired = expireRegister(state, event.time, config);
      if (
        state.shortcutDeadline === null ||
        event.time < state.shortcutDeadline
      ) {
        return expired === state
          ? { commands: [], state }
          : arrange(expired, config);
      }
      const fallback = state.shortcutFallback;
      const surfaceId = state.shortcutSurfaceId;
      state = clearSequence(expired);
      if (fallback) {
        ({ state, commands } = action(
          state,
          {
            action: fallback,
            ...(surfaceId === null ? {} : { surfaceId }),
            time: event.time,
            type: "action",
          },
          config,
          true
        ));
      }
      break;
    }
    case "resize":
      if (
        event.finished === false &&
        !config.adjustLayoutLive &&
        !state.windows.find((window) => window.id === event.id)?.docked
      ) {
        return { commands: [], state };
      }
      state = adjustResize(state, event.id, event.geometry, config);
      break;
    case "drag": {
      state = dragWindow(state, event, config);
      break;
    }
    case "arrange":
      break;
    default:
      return assertNeverEvent(event);
  }
  const arranged = arrange(state, config);
  const dragCommands: Command[] = [];
  if (
    event.type === "drag" ||
    (event.type === "remove" && initialState.drag?.id === event.id)
  ) {
    const dragged = arranged.state.windows.find(
      (window) => window.id === arranged.state.drag?.id
    );
    const surface =
      arranged.state.surfaces.find(
        (entry) => entry.id === dragged?.surfaceId
      ) ?? initialState.surfaces[0];
    if (surface) {
      dragCommands.push({
        area: surface.area,
        geometry:
          config.dragPreview && dragged?.docked ? dragged.geometry : null,
        type: "dragPreview",
      });
    }
  }
  const registerTimer: Command[] =
    event.type === "action" &&
    state.register !== state.registerMode &&
    state.registerEntered !== null
      ? [
          {
            deadline: state.shortcutTime + config.altRegisterTimeout,
            type: "shortcutTimer",
          },
        ]
      : [];
  return {
    commands: [
      ...commands,
      ...registerTimer,
      ...arranged.commands,
      ...dragCommands,
    ],
    state: arranged.state,
  };
}
function assertNeverEvent(event: never): never {
  throw new Error(`Unsupported engine event: ${String(event)}`);
}
