// biome-ignore-all lint/style/useAtIndex: Qt QV4 does not implement Array.prototype.at.
// SPDX-License-Identifier: MIT
// Dock/Columns drag behavior adapted from Vjatcheslav V. Kolchkov's Krohnkite.
import type { Config } from "@krohnkite/config";
import { bottom, center, right } from "./geometry.js";
import { arrangeDocks, ignored, surfaceKey } from "./rules.js";
import type {
  DockPosition,
  EngineEvent,
  EngineState,
  ManagedWindow,
  Point,
  Rect,
  Surface,
} from "./types.js";

const contains = (area: Rect, point: Point): boolean =>
  point.x >= area.x &&
  point.x <= right(area) &&
  point.y >= area.y &&
  point.y <= bottom(area);
const update = (
  state: EngineState,
  id: string,
  fields: Partial<ManagedWindow>
): EngineState => ({
  ...state,
  windows: state.windows.map((window) =>
    window.id === id ? { ...window, ...fields } : window
  ),
});
const dockPositions = (config: Config): DockPosition[] => {
  const positions: DockPosition[] = ["left", "top", "right", "bottom"];
  const orders = {
    bottom: config.dockOrderBottom,
    left: config.dockOrderLeft,
    right: config.dockOrderRight,
    top: config.dockOrderTop,
  };
  return positions
    .filter((position) => orders[position] > 0)
    .sort((first, second) => orders[first] - orders[second]);
};
const onEdge = (
  area: Rect,
  point: Point,
  position: DockPosition,
  pixels: number
): boolean => {
  if (pixels <= 0) {
    return false;
  }
  if (position === "top" || position === "bottom") {
    const edge = position === "top" ? area.y : bottom(area);
    return (
      Math.abs(point.y - edge) <= pixels &&
      point.x >= area.x &&
      point.x <= right(area)
    );
  }
  const edge = position === "left" ? area.x : right(area);
  return (
    Math.abs(point.x - edge) <= pixels &&
    point.y >= area.y &&
    point.y <= bottom(area)
  );
};
const clearPartner = (initialState: EngineState): EngineState => {
  const context = initialState.drag;
  if (!(context?.swappingId && context.swappingPosition)) {
    return initialState;
  }
  let state = update(initialState, context.swappingId, {
    docked: true,
    dockPosition: context.swappingPosition,
    floating: false,
    manualDocked: true,
    manualFloating: false,
  });
  if (context.initialDocked) {
    state = update(state, context.id, {
      dockPosition: context.initialDockPosition,
    });
  }
  return {
    ...state,
    drag: { ...context, swappingId: null, swappingPosition: null },
  };
};

interface DockHit {
  readonly position: DockPosition | null;
  readonly window: ManagedWindow | null;
}
function dockHit(
  state: EngineState,
  surface: Surface,
  window: ManagedWindow,
  point: Point,
  config: Config
): DockHit {
  const members = state.windows.filter(
    (entry) =>
      entry.surfaceId === surface.id &&
      entry.visible !== false &&
      !ignored(entry, config)
  );
  const { area } = arrangeDocks(surface, members, config);
  const zones = {
    bottom: config.dockBottomDragZone,
    left: config.dockLeftDragZone,
    right: config.dockRightDragZone,
    top: config.dockTopDragZone,
  };
  let own: DockPosition | null = null;
  for (const position of dockPositions(config)) {
    const occupant = members.find(
      (entry) => entry.docked && (entry.dockPosition ?? "left") === position
    );
    if (
      occupant?.id === window.id &&
      (position === state.drag?.initialDockPosition || state.drag?.swappingId)
    ) {
      if (!contains(area, point)) {
        own = position;
      }
      continue;
    }
    if (!occupant || occupant.id === window.id) {
      if (onEdge(surface.area, point, position, zones[position])) {
        return { position, window: null };
      }
    } else if (
      surface.id === state.drag?.initialSurfaceId &&
      contains(occupant.geometry, point)
    ) {
      return { position, window: occupant };
    }
  }
  return { position: own, window: null };
}
function dragDock(
  initialState: EngineState,
  surface: Surface,
  window: ManagedWindow,
  point: Point,
  config: Config
): { readonly processed: boolean; readonly state: EngineState } {
  const hit = dockHit(initialState, surface, window, point, config);
  if (hit.position === null) {
    return window.docked
      ? {
          processed: false,
          state: update(clearPartner(initialState), window.id, {
            docked: false,
            floating: false,
            manualDocked: false,
            manualFloating: false,
          }),
        }
      : { processed: false, state: initialState };
  }
  if (hit.window?.id === initialState.drag?.swappingId) {
    const state = clearPartner(initialState);
    return {
      processed: true,
      state: update(state, window.id, {
        docked: state.drag?.initialDocked ?? false,
        manualDocked: state.drag?.initialDocked ?? false,
      }),
    };
  }
  if (
    hit.window === null &&
    window.docked &&
    window.dockPosition === hit.position
  ) {
    return { processed: true, state: initialState };
  }
  let state = clearPartner(initialState);
  if (hit.window && state.drag) {
    const context = state.drag;
    state = update(state, hit.window.id, {
      docked: state.drag.initialDocked,
      dockPosition: state.drag.initialDockPosition,
      floating: false,
      manualDocked: state.drag.initialDocked,
      manualFloating: false,
    });
    state = {
      ...state,
      drag: {
        ...context,
        swappingId: hit.window.id,
        swappingPosition: hit.position,
      },
    };
  }
  return {
    processed: true,
    state: update(state, window.id, {
      docked: true,
      dockPosition: hit.position,
      floating: false,
      manualDocked: true,
      manualFloating: false,
    }),
  };
}

function moveBeside(
  state: EngineState,
  id: string,
  target: string,
  after: boolean
): EngineState {
  const window = state.windows.find((entry) => entry.id === id);
  if (!window) {
    return state;
  }
  const windows = state.windows.filter((entry) => entry.id !== id);
  const index = windows.findIndex((entry) => entry.id === target);
  if (index < 0) {
    return state;
  }
  windows.splice(index + (after ? 1 : 0), 0, window);
  return { ...state, windows };
}
function configuredWeights(surface: Surface, config: Config): number[] {
  for (const line of config.columnsLayerConf) {
    const parts = line.split(":").map((part) => part.trim());
    if (
      parts.length >= 5 &&
      (!parts[0] || parts[0] === surface.screen) &&
      (!parts[1] || parts[1] === surface.activity) &&
      (!parts[2] || parts[2] === (surface.desktopName ?? surface.desktop))
    ) {
      const weights = parts.slice(3).map(Number);
      return weights.every((weight) => Number.isFinite(weight) && weight > 0)
        ? weights
        : [];
    }
  }
  return [];
}
// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: A drag has two edge insertion cases and two ordered window-half cases matching upstream.
function dragColumns(
  state: EngineState,
  surface: Surface,
  window: ManagedWindow,
  point: Point,
  config: Config
): EngineState {
  const key = surfaceKey(surface, config);
  const layout = state.layouts[key];
  if (layout?.id !== "columns") {
    return state;
  }
  const tiles = state.windows.filter(
    (entry) =>
      entry.surfaceId === surface.id &&
      entry.visible !== false &&
      !(entry.floating || entry.docked) &&
      !ignored(entry, config)
  );
  const docking = arrangeDocks(
    surface,
    state.windows.filter((entry) => entry.surfaceId === surface.id),
    config
  );
  const horizontal = layout.rotation === 0 || layout.rotation === 2;
  const primary: DockPosition =
    (["top", "right", "bottom", "left"] as const)[layout.rotation % 4] ?? "top";
  const secondary: DockPosition = (
    { bottom: "top", left: "right", right: "left", top: "bottom" } as const
  )[primary];
  const extent = horizontal ? docking.area.height : docking.area.width;
  const first = onEdge(docking.area, point, primary, extent * 0.1);
  const last = onEdge(docking.area, point, secondary, extent * 0.1);
  const columns = { ...layout.columns };
  const indexes = [
    ...new Set(tiles.map((entry) => columns[entry.id] ?? 0)),
  ].sort((left, rightIndex) => left - rightIndex);
  if (first || last) {
    const edge = first ? (indexes[0] ?? 0) : (indexes[indexes.length - 1] ?? 0);
    const members = tiles.filter((entry) => (columns[entry.id] ?? 0) === edge);
    if (members.length === 1 && members[0]?.id === window.id) {
      return state;
    }
    const configured = configuredWeights(surface, config);
    const limited =
      config.columnsLimitColumns &&
      configured.length > 0 &&
      indexes.length >= configured.length;
    let weights = [...layout.columnWeights];
    if (limited) {
      columns[window.id] = edge;
    } else if (first) {
      for (const id of Object.keys(columns)) {
        columns[id] = (columns[id] ?? 0) + 1;
      }
      columns[window.id] = 0;
      weights.unshift(1);
    } else {
      columns[window.id] = edge + 1;
      weights.push(1);
    }
    if (
      !limited &&
      config.columnsApplyConfOnNewColumns &&
      configured.length > 0
    ) {
      const sum = configured.reduce((total, weight) => total + weight, 0);
      const count = indexes.length + 1;
      weights = weights.map((weight, index) =>
        configured[index] === undefined
          ? weight
          : ((configured[index] ?? 1) * count) / sum
      );
    }
    return {
      ...state,
      layouts: {
        ...state.layouts,
        [key]: { ...layout, columns, columnWeights: weights },
      },
    };
  }
  const target = tiles.find(
    (entry) => entry.id !== window.id && contains(entry.geometry, point)
  );
  if (!target) {
    return state;
  }
  columns[window.id] = columns[target.id] ?? 0;
  const after = horizontal
    ? point.x >= center(target.geometry).x
    : point.y >= center(target.geometry).y;
  const moved = moveBeside(state, window.id, target.id, after);
  return {
    ...moved,
    layouts: { ...state.layouts, [key]: { ...layout, columns } },
  };
}

/** Live dock/Columns edits suppress the dragged client's geometry until release. */
// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: The drag transaction coordinates dock swaps, Columns placement, and the ordinary tile/float drop fallback.
export function dragWindow(
  initialState: EngineState,
  event: Extract<EngineEvent, { type: "drag" }>,
  config: Config
): EngineState {
  const window = initialState.windows.find((entry) => entry.id === event.id);
  const surface = initialState.surfaces.find(
    (entry) => entry.id === window?.surfaceId
  );
  if (!(window && surface) || ignored(window, config)) {
    return initialState;
  }
  let state = initialState;
  if (window.floating) {
    return event.finished
      ? update({ ...state, drag: null }, window.id, {
          floatingGeometry: event.geometry,
          geometry: event.geometry,
        })
      : state;
  }
  if (state.drag?.id !== window.id) {
    state = {
      ...state,
      drag: {
        id: window.id,
        initialDocked: Boolean(window.docked),
        initialDockPosition: window.dockPosition ?? "left",
        initialSurfaceId: surface.id,
        swappingId: null,
        swappingPosition: null,
      },
    };
  }
  const point = event.pointer ?? center(event.geometry);
  const result = dragDock(state, surface, window, point, config);
  ({ state } = result);
  const columns = state.layouts[surfaceKey(surface, config)]?.id === "columns";
  if (!result.processed && columns) {
    state = dragColumns(state, surface, window, point, config);
  }
  if (!event.finished) {
    return state;
  }
  if (!(result.processed || columns)) {
    const target = state.windows.find(
      (entry) =>
        entry.surfaceId === surface.id &&
        entry.id !== window.id &&
        entry.visible !== false &&
        !(entry.floating || entry.docked) &&
        !ignored(entry, config) &&
        contains(entry.geometry, point)
    );
    if (target) {
      const firstIndex = state.windows.findIndex(
        (entry) => entry.id === window.id
      );
      const secondIndex = state.windows.findIndex(
        (entry) => entry.id === target.id
      );
      const windows = [...state.windows];
      const dragged = windows[firstIndex];
      windows[firstIndex] = target;
      if (dragged) {
        windows[secondIndex] = dragged;
      }
      state = { ...state, windows };
    } else if (
      !config.keepTilingOnDrag &&
      Math.hypot(
        event.geometry.x - window.geometry.x,
        event.geometry.y - window.geometry.y
      ) > 30
    ) {
      state = update(state, window.id, {
        docked: false,
        floating: true,
        floatingGeometry: event.geometry,
        manualDocked: false,
        manualFloating: true,
      });
    }
  }
  return update({ ...state, drag: null }, window.id, {
    geometry: event.geometry,
  });
}
