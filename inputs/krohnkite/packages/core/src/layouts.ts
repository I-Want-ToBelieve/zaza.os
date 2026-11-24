// Layout formulas derive from Krohnkite's MIT-licensed layout implementations.
// SPDX-FileCopyrightText: 2018 Eon S. Jeon; 2024-2026 Vjatcheslav V. Kolchkov; 2024 Jas Singh
// SPDX-License-Identifier: MIT
import type { Config } from "@krohnkite/config";
import { bottom, clamp, right, rotated, split } from "./geometry.js";
import type { LayoutState, ManagedWindow, Rect } from "./types.js";

const weights = (windows: readonly ManagedWindow[]): number[] =>
  windows.map((window) => window.weight ?? 1);

function tile(
  area: Rect,
  windows: readonly ManagedWindow[],
  layout: LayoutState,
  gap: number
): Rect[] {
  const count = clamp(layout.masterCount, 0, windows.length);
  if (!count || count === windows.length) {
    return split(area, weights(windows), gap);
  }
  const [master, stack] = split(
    area,
    [layout.ratio, 1 - layout.ratio],
    gap,
    true
  );
  if (!(master && stack)) {
    return [];
  }
  return [
    ...rotated(master, layout.masterRotation, (local) =>
      split(local, weights(windows.slice(0, count)), gap)
    ),
    ...split(stack, weights(windows.slice(count)), gap),
  ];
}
function threeColumn(
  area: Rect,
  windows: readonly ManagedWindow[],
  layout: LayoutState,
  gap: number
): Rect[] {
  const count = Math.max(1, Math.min(layout.masterCount, windows.length));
  if (windows.length <= count + 1) {
    return tile(area, windows, { ...layout, masterCount: count }, gap);
  }
  const remainder = windows.length - count;
  const rightCount = Math.floor(remainder / 2);
  const [leftArea, masterArea, rightArea] = split(
    area,
    [1 - layout.ratio, layout.ratio, 1 - layout.ratio],
    gap,
    true
  );
  if (!(leftArea && masterArea && rightArea)) {
    return [];
  }
  return [
    ...split(masterArea, weights(windows.slice(0, count)), gap),
    ...split(rightArea, weights(windows.slice(count, count + rightCount)), gap),
    ...split(leftArea, weights(windows.slice(count + rightCount)), gap),
  ];
}
function quarter(
  area: Rect,
  count: number,
  layout: LayoutState,
  gap: number
): Rect[] {
  if (count <= 1) {
    return count ? [area] : [];
  }
  const [leftArea, rightArea] = split(
    area,
    [layout.ratio, 1 - layout.ratio],
    gap,
    true
  );
  if (!(leftArea && rightArea)) {
    return [];
  }
  if (count === 2) {
    return [leftArea, rightArea];
  }
  const [rightTop, rightBottom] = split(
    rightArea,
    [layout.quarterRight, 1 - layout.quarterRight],
    gap
  );
  if (!(rightTop && rightBottom)) {
    return [];
  }
  if (count === 3) {
    return [leftArea, rightTop, rightBottom];
  }
  const [leftTop, leftBottom] = split(
    leftArea,
    [layout.quarterLeft, 1 - layout.quarterLeft],
    gap
  );
  return leftTop && leftBottom
    ? [leftTop, rightTop, rightBottom, leftBottom]
    : [];
}
function spiral(
  area: Rect,
  count: number,
  gap: number,
  ratio: number,
  depth = 0
): Rect[] {
  if (!count) {
    return [];
  }
  if (count === 1) {
    return [area];
  }
  const pieces = rotated(area, depth % 4, (local) =>
    split(local, [ratio, 1 - ratio], gap, true)
  );
  const [head, rest] = pieces;
  return head && rest
    ? [head, ...spiral(rest, count - 1, gap, ratio, depth + 1)]
    : [];
}
function binaryTree(area: Rect, count: number, gap: number, depth = 0): Rect[] {
  if (!count) {
    return [];
  }
  if (count === 1) {
    return [area];
  }
  const level = Math.ceil(Math.log2(count));
  const capacity = 2 ** (level - 1);
  const halfCapacity = 2 ** Math.max(0, level - 2);
  const firstAtRoot =
    count > capacity + halfCapacity ? count - capacity : halfCapacity;
  const first = depth === 0 ? firstAtRoot : Math.floor(count / 2);
  const [primary, secondary] = split(area, [1, 1], gap, depth % 2 === 0);
  return primary && secondary
    ? [
        ...binaryTree(primary, first, gap, depth + 1),
        ...binaryTree(secondary, count - first, gap, depth + 1),
      ]
    : [];
}
function columns(
  area: Rect,
  windows: readonly ManagedWindow[],
  layout: LayoutState,
  gap: number
): Rect[] {
  const indexes = [
    ...new Set(windows.map((window) => layout.columns[window.id] ?? 0)),
  ].sort((left, rightIndex) => left - rightIndex);
  const direction = ((layout.rotation % 4) + 4) % 4;
  if (direction === 1 || direction === 2) {
    indexes.reverse();
  }
  const horizontal = direction === 1 || direction === 3;
  const areas = split(
    area,
    indexes.map((index) => layout.columnWeights[index] ?? 1),
    gap,
    horizontal
  );
  const geometries = new Map<string, Rect>();
  indexes.forEach((column, index) => {
    const members = windows.filter(
      (window) => (layout.columns[window.id] ?? 0) === column
    );
    const columnArea = areas[index];
    if (!columnArea) {
      return;
    }
    split(columnArea, weights(members), gap, !horizontal).forEach(
      (geometry, member) => {
        const window = members[member];
        if (window) {
          geometries.set(window.id, geometry);
        }
      }
    );
  });
  return windows.map((window) => geometries.get(window.id) ?? area);
}

/** All twelve upstream layout families, with geometry independent of KWin and Effect. */
export function arrangeLayout(
  area: Rect,
  windows: readonly ManagedWindow[],
  layout: LayoutState,
  config: Config,
  gap: number
): Rect[] {
  const count = windows.length;
  if (!count) {
    return [];
  }
  switch (layout.id) {
    case "floating":
      return windows.map(
        (window) => window.floatingGeometry ?? window.geometry
      );
    case "monocle":
      return windows.map(() => area);
    case "tile":
      return rotated(area, layout.rotation, (local) =>
        tile(local, windows, layout, gap)
      );
    case "threeColumn":
      return rotated(area, layout.rotation, (local) =>
        threeColumn(local, windows, layout, gap)
      );
    case "stacked":
      return rotated(area, layout.rotation, (local) => {
        const masterCount = Math.max(
          1,
          Math.min(layout.masterCount, windows.length)
        );
        if (windows.length <= masterCount) {
          return split(local, weights(windows), gap);
        }
        const [master, stack] = split(
          local,
          [layout.ratio, 1 - layout.ratio],
          gap
        );
        return master && stack
          ? [
              ...split(master, weights(windows.slice(0, masterCount)), gap),
              ...split(stack, weights(windows.slice(masterCount)), gap),
            ]
          : [];
      });
    case "columns":
      return columns(area, windows, layout, gap);
    case "spiral":
      return rotated(area, layout.rotation, (local) =>
        spiral(local, count, gap, layout.ratio)
      );
    case "binaryTree":
      return rotated(area, layout.rotation, (local) =>
        binaryTree(local, count, gap)
      );
    case "quarter":
      return rotated(area, layout.rotation, (local) =>
        quarter(local, Math.min(4, count), layout, gap)
      );
    case "spread": {
      const step = Math.floor(area.width * layout.spread);
      let visible = count;
      while (
        visible > 1 &&
        area.width - step * (visible - 1) < area.width * 0.4
      ) {
        visible -= 1;
      }
      const width = Math.max(1, area.width - step * (visible - 1));
      const sorted = [...windows].sort(
        (leftWindow, rightWindow) =>
          (leftWindow.stackingOrder ?? 0) - (rightWindow.stackingOrder ?? 0)
      );
      const geometries = new Map(
        sorted.map((window, index) => [
          window.id,
          {
            height: area.height,
            width,
            x: area.x + (index < visible ? step * (visible - index - 1) : 0),
            y: area.y,
          },
        ])
      );
      return windows.map((window) => geometries.get(window.id) ?? area);
    }
    case "stair":
      return windows.map((_window, index) => {
        const dx = Math.min(
          layout.stair * (count - index - 1),
          Math.max(0, area.width - 1)
        );
        const dy = Math.min(layout.stair * index, Math.max(0, area.height - 1));
        return {
          height: area.height - dy,
          width: area.width - dx,
          x: area.x + (config.stairReverse ? 0 : dx),
          y: area.y + dy,
        };
      });
    case "cascade": {
      const directions = [
        [-1, -1],
        [0, -1],
        [1, -1],
        [1, 0],
        [1, 1],
        [0, 1],
        [-1, 1],
        [-1, 0],
      ] as const;
      const [dx, dy] = directions[layout.cascade % 8] ?? [1, 1];
      const step = Math.min(
        25,
        (area.width - 1) / Math.max(1, count - 1),
        (area.height - 1) / Math.max(1, count - 1)
      );
      const width = area.width - Math.abs(dx) * step * (count - 1);
      const height = area.height - Math.abs(dy) * step * (count - 1);
      const baseX = dx < 0 ? right(area) - width : area.x;
      const baseY = dy < 0 ? bottom(area) - height : area.y;
      return windows.map((_window, index) => ({
        height,
        width,
        x: baseX + dx * step * index,
        y: baseY + dy * step * index,
      }));
    }
    default:
      return assertNeverLayout(layout.id);
  }
}
function assertNeverLayout(id: never): never {
  throw new Error(`Unsupported layout: ${String(id)}`);
}
