export interface Rect {
  readonly height: number;
  readonly width: number;
  readonly x: number;
  readonly y: number;
}

export interface QtSignal<Args extends unknown[] = []> {
  readonly connect: (callback: (...args: Args) => void) => void;
  readonly disconnect: (callback: (...args: Args) => void) => void;
}

export interface VirtualDesktop {
  readonly id: string;
  readonly name?: string;
}

export interface Output {
  readonly currentDesktop?: VirtualDesktop;
  readonly geometry?: Rect;
  readonly name: string;
}

/** The supported Qt 6 KWin boundary, rather than a browser or Node global. */
export interface KWinWindow {
  readonly activities?: readonly string[];
  readonly activitiesChanged?: QtSignal;
  readonly bufferGeometryChanged?: QtSignal;
  readonly caption?: string;
  readonly captionChanged?: QtSignal;
  readonly deleted?: boolean;
  desktops?: readonly VirtualDesktop[];
  readonly desktopsChanged?: QtSignal;
  readonly dialog?: boolean;
  readonly dock?: boolean;
  frameGeometry: Rect;
  readonly frameGeometryChanged?: QtSignal;
  readonly fullScreen?: boolean;
  readonly fullScreenChanged?: QtSignal;
  readonly hidden?: boolean;
  readonly hiddenChanged?: QtSignal;
  readonly interactiveMoveResizeFinished?: QtSignal;
  readonly interactiveMoveResizeStepped?: QtSignal<[Rect]>;
  readonly internalId: string | number;
  keepAbove?: boolean;
  keepBelow?: boolean;
  readonly maximizedAboutToChange?: QtSignal<[number]>;
  readonly maximizedChanged?: QtSignal;
  readonly maximizeMode?: number;
  readonly maxSize?: { readonly width: number; readonly height: number };
  minimized?: boolean;
  readonly minimizedChanged?: QtSignal;
  readonly minSize?: { readonly width: number; readonly height: number };
  readonly modal?: boolean;
  readonly move?: boolean;
  readonly moveResizedChanged?: QtSignal;
  noBorder?: boolean;
  readonly normalWindow?: boolean;
  readonly output?: Output;
  readonly outputChanged?: QtSignal;
  readonly popupWindow?: boolean;
  readonly resize?: boolean;
  readonly resizeable?: boolean;
  readonly resourceClass?: string;
  readonly resourceName?: string;
  readonly setMaximize?: (vertically: boolean, horizontally: boolean) => void;
  readonly skipPager?: boolean;
  readonly skipPagerChanged?: QtSignal;
  readonly specialWindow?: boolean;
  readonly splash?: boolean;
  readonly stackingOrder?: number;
  readonly stackingOrderChanged?: QtSignal;
  readonly transient?: boolean;
  readonly utility?: boolean;
  readonly windowRole?: string;
}

export interface Workspace {
  readonly activeScreen: Output;
  activeWindow: KWinWindow | null;
  readonly activityRemoved?: QtSignal<[string]>;
  readonly clientArea: (
    option: number,
    output: Output,
    desktop: VirtualDesktop
  ) => Rect;
  readonly currentActivity: string;
  readonly currentActivityChanged?: QtSignal<[string]>;
  readonly currentDesktop: VirtualDesktop;
  readonly currentDesktopChanged?: QtSignal<[VirtualDesktop]>;
  readonly currentDesktopForScreen?: (output: Output) => VirtualDesktop | null;
  readonly cursorPos?: { readonly x: number; readonly y: number } | null;
  readonly desktops?: readonly VirtualDesktop[];
  readonly desktopsChanged?: QtSignal;
  readonly screens: readonly Output[];
  readonly screensChanged?: QtSignal;
  readonly sendClientToScreen?: (window: KWinWindow, output: Output) => void;
  readonly stackingOrder: readonly KWinWindow[];
  readonly virtualScreenGeometryChanged?: QtSignal;
  readonly windowActivated: QtSignal<[KWinWindow | null]>;
  readonly windowAdded: QtSignal<[KWinWindow]>;
  readonly windowRemoved: QtSignal<[KWinWindow]>;
}

export interface ShortcutEntry {
  readonly hdl: { readonly activated: QtSignal };
  readonly name: string;
}

export interface KWinApi {
  readonly kwin: { readonly PlacementArea: number };
  readonly log: (message: string) => void;
  readonly movePointerToCenter?: () => void;
  readonly movePointerToFocus?: () => void;
  readonly notify?: (message: string) => void;
  readonly preview?: (geometry: Rect | null, area: Rect) => void;
  readonly queryVirtualKeyboard?: (
    callback: (visible: boolean) => void
  ) => () => void;
  readonly readConfig: (name: string, fallback: unknown) => unknown;
  readonly scheduleTimer?: (
    milliseconds: number,
    callback: () => void
  ) => () => void;
  readonly shortcuts: readonly ShortcutEntry[];
  readonly workspace: Workspace;
}
