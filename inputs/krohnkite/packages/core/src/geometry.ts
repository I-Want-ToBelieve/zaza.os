// SPDX-FileCopyrightText: 2018 Eon S. Jeon; 2024-2026 Vjatcheslav V. Kolchkov
// SPDX-License-Identifier: MIT
import type { Rect } from "./types.js";
export const clamp = (value: number, min: number, max: number): number =>
  Math.min(max, Math.max(min, value));
export const right = (rect: Rect): number => rect.x + rect.width;
export const bottom = (rect: Rect): number => rect.y + rect.height;
export const center = (
  rect: Rect
): { readonly x: number; readonly y: number } => ({
  x: rect.x + rect.width / 2,
  y: rect.y + rect.height / 2,
});
export function inset(
  area: Rect,
  left: number,
  top: number,
  rightGap: number,
  bottomGap: number
): Rect {
  const x = Math.min(Math.max(0, left), Math.max(0, area.width - 1));
  const y = Math.min(Math.max(0, top), Math.max(0, area.height - 1));
  return {
    height: Math.max(1, area.height - y - Math.max(0, bottomGap)),
    width: Math.max(1, area.width - x - Math.max(0, rightGap)),
    x: area.x + x,
    y: area.y + y,
  };
}
/** Integer endpoints make adjacent tiles cover the entire available span. */
export function split(
  area: Rect,
  weights: readonly number[],
  gap: number,
  horizontal = false
): Rect[] {
  if (!weights.length) {
    return [];
  }
  const span = horizontal ? area.width : area.height;
  const effectiveGap = Math.min(
    Math.max(0, gap),
    Math.max(0, (span - weights.length) / Math.max(1, weights.length - 1))
  );
  const usable = span - effectiveGap * (weights.length - 1);
  const positive = weights.map((weight) =>
    Number.isFinite(weight) && weight > 0 ? weight : 1
  );
  const total = positive.reduce((sum, weight) => sum + weight, 0);
  let previous = 0;
  let cumulative = 0;
  return positive.map((weight, index) => {
    cumulative += weight;
    const end =
      index === positive.length - 1
        ? usable
        : Math.round((usable * cumulative) / total);
    const offset = previous + effectiveGap * index;
    const size = Math.max(1, end - previous);
    previous = end;
    return horizontal
      ? { height: area.height, width: size, x: area.x + offset, y: area.y }
      : { height: size, width: area.width, x: area.x, y: area.y + offset };
  });
}
export function constrain(rect: Rect, area: Rect): Rect {
  const width = clamp(rect.width, 1, area.width);
  const height = clamp(rect.height, 1, area.height);
  return {
    height,
    width,
    x: clamp(rect.x, area.x, right(area) - width),
    y: clamp(rect.y, area.y, bottom(area) - height),
  };
}
export function sameRect(left: Rect, rightRect: Rect): boolean {
  return (
    left.x === rightRect.x &&
    left.y === rightRect.y &&
    left.width === rightRect.width &&
    left.height === rightRect.height
  );
}
export function rotated(
  area: Rect,
  angle: number,
  arrange: (local: Rect) => readonly Rect[]
): Rect[] {
  const turn = ((angle % 4) + 4) % 4;
  const odd = turn % 2 === 1;
  const local = {
    height: odd ? area.width : area.height,
    width: odd ? area.height : area.width,
    x: 0,
    y: 0,
  };
  return arrange(local).map((rect) => {
    switch (turn) {
      // Krohnkite rotates the split axis while keeping stack order, rather than
      // rotating each window's content coordinates around the screen center.
      case 1:
        return {
          height: rect.width,
          width: rect.height,
          x: area.x + rect.y,
          y: area.y + rect.x,
        };
      case 2:
        return {
          height: rect.height,
          width: rect.width,
          x: right(area) - rect.x - rect.width,
          y: area.y + rect.y,
        };
      case 3:
        return {
          height: rect.width,
          width: rect.height,
          x: area.x + rect.y,
          y: bottom(area) - rect.x - rect.width,
        };
      default:
        return {
          height: rect.height,
          width: rect.width,
          x: area.x + rect.x,
          y: area.y + rect.y,
        };
    }
  });
}
