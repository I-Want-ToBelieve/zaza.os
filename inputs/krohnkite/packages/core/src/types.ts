// SPDX-License-Identifier: MIT
import type { Action, LayoutId } from "@krohnkite/config";

export type { Action, LayoutId } from "@krohnkite/config";
export interface Rect {
  readonly height: number;
  readonly width: number;
  readonly x: number;
  readonly y: number;
}
export interface Point {
  readonly x: number;
  readonly y: number;
}
export interface Surface {
  readonly active?: boolean;
  readonly activity: string;
  readonly activityName?: string;
  readonly area: Rect;
  readonly desktop: string;
  readonly desktopName?: string;
  readonly id: string;
  readonly screen: string;
}
export type DockPosition = "left" | "top" | "right" | "bottom";
export interface ManagedWindow {
  readonly caption: string;
  readonly dialog?: boolean;
  readonly docked?: boolean;
  readonly dockOverrides?: Readonly<Record<string, string>>;
  readonly dockPosition?: DockPosition;
  readonly dockRendered?: boolean;
  readonly floating?: boolean;
  readonly floatingGeometry?: Rect;
  readonly focusTime?: number;
  readonly fullScreen?: boolean;
  readonly geometry: Rect;
  readonly id: string;
  readonly layoutMaximized?: boolean;
  readonly layoutMinimized?: boolean;
  readonly manualDocked?: boolean;
  readonly manualFloating?: boolean;
  readonly maximized?: boolean;
  readonly maxSize?: { readonly width: number; readonly height: number };
  readonly minimized?: boolean;
  readonly minSize?: { readonly width: number; readonly height: number };
  readonly modal?: boolean;
  readonly resizeable?: boolean;
  readonly resourceClass: string;
  readonly resourceName?: string;
  readonly role: string;
  readonly skipPager?: boolean;
  readonly specialWindow?: boolean;
  readonly splash?: boolean;
  readonly stackingOrder?: number;
  readonly surfaceId: string;
  readonly transient?: boolean;
  readonly utility?: boolean;
  readonly visible?: boolean;
  readonly weight?: number;
}
export interface LayoutState {
  readonly capacity: number | null;
  readonly cascade: number;
  readonly columns: Readonly<Record<string, number>>;
  readonly columnWeights: readonly number[];
  readonly id: LayoutId;
  readonly masterCount: number;
  readonly masterRotation: number;
  readonly previousCount: number;
  readonly previousId: LayoutId;
  readonly previousMasterId: string | null;
  readonly quarterLeft: number;
  readonly quarterRight: number;
  readonly ratio: number;
  readonly rotation: number;
  readonly spread: number;
  readonly stair: number;
}
export interface DragState {
  readonly id: string;
  readonly initialDocked: boolean;
  readonly initialDockPosition: DockPosition;
  readonly initialSurfaceId: string;
  readonly swappingId: string | null;
  readonly swappingPosition: DockPosition | null;
}
export interface EngineState {
  readonly clock: number;
  readonly drag: DragState | null;
  readonly focusId: string | null;
  readonly layouts: Readonly<Record<string, LayoutState>>;
  readonly register: boolean;
  readonly registerEntered: number | null;
  readonly registerMode: boolean;
  readonly shortcutDeadline: number | null;
  readonly shortcutFallback: Action | null;
  readonly shortcutKeys: readonly string[];
  readonly shortcutSurfaceId: string | null;
  readonly shortcutTime: number;
  readonly surfaces: readonly Surface[];
  readonly windows: readonly ManagedWindow[];
}
export type EngineEvent =
  | { readonly type: "upsert"; readonly window: ManagedWindow }
  | { readonly type: "remove"; readonly id: string }
  | { readonly type: "focus"; readonly id: string | null }
  | { readonly type: "surfaces"; readonly surfaces: readonly Surface[] }
  | {
      readonly type: "action";
      readonly action: Action;
      readonly surfaceId?: string;
      readonly shortcut?: string;
      readonly time?: number;
    }
  | {
      readonly type: "resize";
      readonly id: string;
      readonly geometry: Rect;
      readonly finished?: boolean;
    }
  | {
      readonly type: "drag";
      readonly id: string;
      readonly geometry: Rect;
      readonly finished: boolean;
      readonly pointer?: Point;
    }
  | { readonly type: "shortcutTimeout"; readonly time: number }
  | { readonly type: "arrange" };
export type Command =
  | {
      readonly type: "dragPreview";
      readonly geometry: Rect | null;
      readonly area: Rect;
    }
  | { readonly type: "geometry"; readonly id: string; readonly geometry: Rect }
  | { readonly type: "focus"; readonly id: string }
  | { readonly type: "border"; readonly id: string; readonly noBorder: boolean }
  | { readonly type: "layer"; readonly id: string; readonly layer: number }
  | {
      readonly type: "minimize";
      readonly id: string;
      readonly minimized: boolean;
    }
  | {
      readonly type: "maximize";
      readonly id: string;
      readonly maximized: boolean;
    }
  | {
      readonly type: "surface";
      readonly id: string;
      readonly surfaceId: string;
    }
  | { readonly type: "shortcutTimer"; readonly deadline: number }
  | { readonly type: "notify"; readonly message: string };
export interface Transition {
  readonly commands: readonly Command[];
  readonly state: EngineState;
}
