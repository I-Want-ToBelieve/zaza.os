// biome-ignore-all lint/style/useAtIndex: Qt QV4 does not implement Array.prototype.at.
// SPDX-License-Identifier: MIT
import type { Config } from "@krohnkite/config";
import { clamp, inset } from "./geometry.js";
import type { DockPosition, ManagedWindow, Rect, Surface } from "./types.js";
export const matchesClass = (
  classes: readonly string[],
  value: string
): boolean => classes.includes(value);
export function ignored(window: ManagedWindow, config: Config): boolean {
  return (
    Boolean(window.specialWindow) ||
    window.resourceClass === "plasmashell" ||
    matchesClass(config.ignoreClass, window.resourceClass) ||
    (window.resourceName !== undefined &&
      matchesClass(config.ignoreClass, window.resourceName)) ||
    config.ignoreRole.includes(window.role) ||
    config.ignoreTitle.some((title) => window.caption.includes(title)) ||
    (config.tileNothing &&
      !matchesClass(config.tilingClass, window.resourceClass))
  );
}
export function ignoredSurface(surface: Surface, config: Config): boolean {
  return (
    config.ignoreScreen.includes(surface.screen) ||
    config.ignoreVDesktop.includes(surface.desktopName ?? surface.desktop) ||
    config.ignoreActivity.includes(surface.activityName ?? surface.activity)
  );
}
export function surfaceMatches(
  surface: Surface,
  label: string,
  config?: Config
): boolean {
  const definition = config?.srfDefineCfg.find(
    (entry) => entry.slice(0, entry.indexOf("=")).trim() === label
  );
  if (definition) {
    const [outputs = "", desktops = "", activity = ""] = definition
      .slice(definition.indexOf("=") + 1)
      .split(":")
      .map((part) => part.trim());
    return (
      (!outputs ||
        outputs
          .split(",")
          .map((entry) => entry.trim())
          .includes(surface.screen)) &&
      (!desktops ||
        desktops
          .split(",")
          .map((entry) => entry.trim())
          .includes(surface.desktopName ?? surface.desktop)) &&
      (!activity || activity === surface.activity)
    );
  }
  const parts = label.split("/");
  return (
    (!parts[0] || parts[0] === surface.screen) &&
    (!parts[1] ||
      parts[1] === surface.activity ||
      parts[1] === surface.activityName) &&
    (!parts[2] ||
      parts[2] === surface.desktop ||
      parts[2] === surface.desktopName)
  );
}
export function surfaceKey(surface: Surface, config: Config): string {
  return JSON.stringify([
    surface.screen,
    config.layoutPerActivity ? surface.activity : "",
    config.layoutPerDesktop ? surface.desktop : "",
  ]);
}
export interface Gaps {
  readonly between: number;
  readonly bottom: number;
  readonly left: number;
  readonly right: number;
  readonly top: number;
}
export function getGaps(surface: Surface, config: Config): Gaps {
  const gaps = {
    between: config.screenGapBetween,
    bottom: config.screenGapBottom,
    left: config.screenGapLeft,
    right: config.screenGapRight,
    top: config.screenGapTop,
  };
  const keys: Readonly<Record<string, keyof Gaps>> = {
    b: "bottom",
    between: "between",
    bottom: "bottom",
    e: "between",
    l: "left",
    left: "left",
    r: "right",
    right: "right",
    t: "top",
    top: "top",
  };
  for (const line of config.gapsOverrideConfig) {
    const separator = line.indexOf(":");
    if (
      separator < 0 ||
      !surfaceMatches(surface, line.slice(0, separator).trim(), config)
    ) {
      continue;
    }
    for (const item of line.slice(separator + 1).split(",")) {
      const [key, value] = item.split("=").map((part) => part.trim());
      const field = key ? keys[key] : undefined;
      const number = Number(value);
      if (field && value && Number.isFinite(number) && number >= 0) {
        gaps[field] = number;
      }
    }
    break;
  }
  return gaps;
}
export function initialFloating(
  window: ManagedWindow,
  config: Config
): boolean {
  return (
    config.floatAsDefault ||
    config.floatingClass.includes(window.resourceClass) ||
    (window.resourceName !== undefined &&
      config.floatingClass.includes(window.resourceName)) ||
    config.floatingTitle.some((title) => window.caption.includes(title)) ||
    Boolean(window.modal) ||
    Boolean(window.transient) ||
    window.resizeable === false ||
    (config.floatUtility &&
      Boolean(window.dialog || window.splash || window.utility)) ||
    (config.floatSkipPagerWindows && Boolean(window.skipPager)) ||
    floatRule(window, config)?.float === true
  );
}
export interface FloatRule {
  readonly auto: boolean;
  readonly float: boolean;
  readonly height?: number | undefined;
  readonly left?: string | undefined;
  readonly stepHeight?: number | undefined;
  readonly stepWidth?: number | undefined;
  readonly top?: string | undefined;
  readonly width?: number | undefined;
}
export function floatRule(
  window: ManagedWindow,
  config: Config
): FloatRule | undefined {
  for (const line of config.floatConfig) {
    const parts = line.split(":");
    const classes = parts[0]?.split(",").map((entry) => entry.trim()) ?? [];
    if (classes.some(Boolean) && !classes.includes(window.resourceClass)) {
      continue;
    }
    if (parts.length === 3 && !window.caption.includes(parts[1] ?? "")) {
      continue;
    }
    const values = Object.fromEntries(
      (parts[parts.length - 1] ?? "")
        .split(",")
        .map((entry) => entry.split("=").map((part) => part.trim()))
    );
    const number = (long: string, short: string): number | undefined => {
      const raw = values[long] ?? values[short];
      const value = Number(raw);
      return raw && Number.isFinite(value) ? value : undefined;
    };
    return {
      auto: ["true", "1"].includes(values.auto ?? values.a ?? "false"),
      float:
        (values.shouldfloat ?? values.f ?? "true") !== "false" &&
        (values.shouldfloat ?? values.f) !== "0",
      height: number("height", "h"),
      left: values.leftindent ?? values.li ?? values.left,
      stepHeight: number("stepheight", "sh"),
      stepWidth: number("stepwidth", "sw"),
      top: values.topindent ?? values.ti ?? values.top,
      width: number("width", "w"),
    };
  }
  return undefined;
}
export function floatingRect(
  window: ManagedWindow,
  surface: Surface,
  config: Config
): Rect {
  const rule = floatRule(window, config);
  const baseline = window.floatingGeometry ?? window.geometry;
  if (!(rule || config.floatDefaultSizeEnable)) {
    return baseline;
  }
  const width =
    rule?.width !== undefined || config.floatDefaultSizeEnable
      ? (surface.area.width *
          clamp(rule?.width ?? config.floatDefaultWidth, 1, 100)) /
        100
      : baseline.width;
  const height =
    rule?.height !== undefined || config.floatDefaultSizeEnable
      ? (surface.area.height *
          clamp(rule?.height ?? config.floatDefaultHeight, 1, 100)) /
        100
      : baseline.height;
  const indent = (
    text: string | undefined,
    dimension: number,
    centered: number
  ): number => {
    if (!text) {
      return centered;
    }
    return text.endsWith("%")
      ? (dimension * Number.parseFloat(text)) / 100
      : Number.parseFloat(text);
  };
  return {
    height,
    width,
    x:
      surface.area.x +
      indent(rule?.left, surface.area.width, (surface.area.width - width) / 2),
    y:
      surface.area.y +
      indent(
        rule?.top,
        surface.area.height,
        (surface.area.height - height) / 2
      ),
  };
}
export function dockRule(
  window: ManagedWindow,
  config: Config
):
  | {
      readonly auto: boolean;
      readonly position: DockPosition;
      readonly priority: number;
      readonly values: Readonly<Record<string, string>>;
    }
  | undefined {
  for (const line of config.dockWindowClassConfig) {
    const parts = line.split(":");
    if (parts[0]?.trim() !== window.resourceClass) {
      continue;
    }
    if (parts.length === 4 && !window.caption.includes(parts[1] ?? "")) {
      continue;
    }
    const flags = (parts[parts.length - 2] ?? "")
      .split(",")
      .map((flag) => flag.trim().toLowerCase());
    const positions: Readonly<Record<string, DockPosition>> = {
      b: "bottom",
      bottom: "bottom",
      l: "left",
      left: "left",
      r: "right",
      right: "right",
      t: "top",
      top: "top",
    };
    const position =
      flags
        .map((flag) => positions[flag])
        .find((entry) => entry !== undefined) ?? "left";
    return {
      auto: flags.includes("auto") || flags.includes("a"),
      position,
      priority: flags.includes("pin") || flags.includes("p") ? 5 : 1,
      values: Object.fromEntries(
        (parts[parts.length - 1] ?? "")
          .split(",")
          .map((entry) => entry.split("=").map((part) => part.trim()))
      ),
    };
  }
  return undefined;
}
export interface DockArrangement {
  readonly area: Rect;
  readonly geometries: ReadonlyMap<string, Rect>;
}
export function dockValues(
  surface: Surface,
  window: ManagedWindow,
  config: Config
): Readonly<Record<string, string>> {
  const line = config.dockSurfacesConfig.find((entry) =>
    surfaceMatches(surface, entry.split(":")[0] ?? "", config)
  );
  return {
    ...Object.fromEntries(
      (line?.slice((line.indexOf(":") ?? -1) + 1) ?? "")
        .split(",")
        .map((entry) => entry.split("=").map((part) => part.trim()))
    ),
    ...dockRule(window, config)?.values,
    ...window.dockOverrides,
  };
}
export function assignDockSlots(
  windows: readonly ManagedWindow[],
  config: Config
): readonly ManagedWindow[] {
  const orders = {
    bottom: config.dockOrderBottom,
    left: config.dockOrderLeft,
    right: config.dockOrderRight,
    top: config.dockOrderTop,
  };
  const positions: DockPosition[] = ["left", "top", "right", "bottom"];
  const slots = positions
    .filter((position) => orders[position] > 0)
    .sort((first, second) => orders[first] - orders[second]);
  const pending = windows.filter((window) => window.docked);
  const assigned = new Map<string, DockPosition>();
  const choose = (
    contenders: readonly ManagedWindow[]
  ): ManagedWindow | undefined => {
    const ranked = [...contenders].sort(
      (first, second) =>
        (dockRule(first, config)?.priority ?? 1) -
          (dockRule(second, config)?.priority ?? 1) ||
        Number(Boolean(first.dockRendered)) -
          Number(Boolean(second.dockRendered))
    );
    return ranked[ranked.length - 1];
  };
  for (const position of slots) {
    const winner = choose(
      pending.filter((window) => (window.dockPosition ?? "left") === position)
    );
    if (winner) {
      assigned.set(winner.id, position);
      pending.splice(pending.indexOf(winner), 1);
    }
  }
  for (const position of slots.filter(
    (entry) => ![...assigned.values()].includes(entry)
  )) {
    const winner = choose(pending);
    if (winner) {
      assigned.set(winner.id, position);
      pending.splice(pending.indexOf(winner), 1);
    }
  }
  return windows.map((window) => {
    if (!window.docked) {
      return window;
    }
    const position = assigned.get(window.id);
    return position
      ? { ...window, dockPosition: position, dockRendered: true }
      : { ...window, docked: false, manualDocked: false };
  });
}
// biome-ignore lint/complexity/noExcessiveCognitiveComplexity: The four dock edges share formulas with explicit horizontal and alignment branches.
export function arrangeDocks(
  surface: Surface,
  windows: readonly ManagedWindow[],
  config: Config
): DockArrangement {
  let { area } = surface;
  const geometries = new Map<string, Rect>();
  const positions: DockPosition[] = ["left", "top", "right", "bottom"];
  const orders = {
    bottom: config.dockOrderBottom,
    left: config.dockOrderLeft,
    right: config.dockOrderRight,
    top: config.dockOrderTop,
  };
  // Upstream reserves vertical docks first on wide outputs, horizontal on tall ones.
  positions.splice(
    0,
    positions.length,
    ...(surface.area.width > surface.area.height
      ? (["left", "right", "top", "bottom"] as const)
      : (["top", "bottom", "left", "right"] as const))
  );
  for (const position of positions) {
    if (orders[position] <= 0) {
      continue;
    }
    const members = windows.filter(
      (window) => window.docked && (window.dockPosition ?? "left") === position
    );
    for (const window of members) {
      const values = dockValues(surface, window, config);
      const number = (key: string, baseline: number): number => {
        let aliases: Readonly<Record<string, number>> = {};
        if (key === "ha") {
          aliases = { c: 0, center: 0, l: 1, left: 1, r: 2, right: 2 };
        } else if (key === "va") {
          aliases = { b: 2, bottom: 2, c: 0, center: 0, t: 1, top: 1 };
        } else if (key === "he" || key === "ve") {
          aliases = { i: 2, inside: 2, m: 1, middle: 1, o: 0, outside: 0 };
        }
        const value =
          aliases[(values[key] ?? "").toLowerCase()] ?? Number(values[key]);
        return values[key] && Number.isFinite(value) ? value : baseline;
      };
      const horizontal = position === "top" || position === "bottom";
      const thickness = horizontal
        ? (surface.area.height *
            clamp(number("hh", config.dockHHeight), 1, 50)) /
          100
        : (surface.area.width * clamp(number("vw", config.dockVWide), 1, 50)) /
          100;
      let length = horizontal
        ? Math.min(
            area.width,
            (surface.area.width *
              clamp(number("hw", config.dockHWide), 1, 100)) /
              100
          )
        : Math.min(
            area.height,
            (surface.area.height *
              clamp(number("vh", config.dockVHeight), 1, 100)) /
              100
          );
      const gap = Math.max(
        0,
        horizontal
          ? number("hgh", config.dockHGap)
          : number("vgv", config.dockVGap)
      );
      const edgeGap = Math.max(
        0,
        horizontal
          ? number("hgv", config.dockHEdgeGap)
          : number("vgh", config.dockVEdgeGap)
      );
      const alignment = horizontal
        ? number("ha", config.dockHAlignment)
        : number("va", config.dockVAlignment);
      const edge = horizontal
        ? number("he", config.dockHEdgeAlignment)
        : number("ve", config.dockVEdgeAlignment);
      const span = horizontal ? area.width : area.height;
      let offset = 0;
      if (2 * gap < length) {
        if (span - length < 2 * gap) {
          offset = gap;
          length -= 2 * gap;
        } else if (alignment === 0) {
          offset = (span - length) / 2;
        } else if (alignment === 1) {
          offset = gap;
        } else {
          offset = span - length - gap;
        }
      }
      const far = position === "right" || position === "bottom";
      let inward = 0;
      let visibleThickness = thickness;
      if (2 * edgeGap <= thickness) {
        visibleThickness -= edge === 1 ? 2 * edgeGap : edgeGap;
        if (edge === 1 || (edge === 0 && far) || (edge === 2 && !far)) {
          inward = edgeGap;
        }
      }
      const rect = horizontal
        ? {
            height: visibleThickness,
            width: length,
            x: area.x + offset,
            y:
              position === "top"
                ? area.y + inward
                : surface.area.y + surface.area.height - thickness + inward,
          }
        : {
            height: length,
            width: visibleThickness,
            x:
              position === "left"
                ? area.x + inward
                : surface.area.x + surface.area.width - thickness + inward,
            y: area.y + offset,
          };
      geometries.set(window.id, rect);
      const reserved = thickness;
      area = inset(
        area,
        position === "left" ? reserved : 0,
        position === "top" ? reserved : 0,
        position === "right" ? reserved : 0,
        position === "bottom" ? reserved : 0
      );
    }
  }
  return { area, geometries };
}
