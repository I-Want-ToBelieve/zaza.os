import {
  type Config,
  defaultConfig,
  readConfig,
  shortcutActions,
} from "@krohnkite/config";
import type {
  Command,
  EngineEvent,
  ManagedWindow,
  Rect,
  Surface,
} from "@krohnkite/core";
import {
  type KWinApiError,
  KWinScriptApi,
  runKWinSync,
  runKWinSyncExit,
} from "@krohnkite/kwinscript-api";
import {
  CompositorError,
  createEngineRuntime,
  type EngineRuntime,
  formatCause,
  type HostService,
} from "@krohnkite/runtime";
import * as Cause from "effect/Cause";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Scope from "effect/Scope";
import type {
  KWinApi,
  KWinWindow,
  Output,
  QtSignal,
  VirtualDesktop,
} from "./types.ts";

export type {
  KWinApi,
  KWinWindow,
  Output,
  QtSignal,
  ShortcutEntry,
  VirtualDesktop,
  Workspace,
} from "./types.ts";

const rect = (geometry: Rect): Rect => ({
  height: geometry.height,
  width: geometry.width,
  x: geometry.x,
  y: geometry.y,
});
const sameRect = (left: Rect, right: Rect): boolean =>
  left.x === right.x &&
  left.y === right.y &&
  left.width === right.width &&
  left.height === right.height;
const surfaceId = (
  output: Output,
  desktop: VirtualDesktop,
  activity: string
): string => `${output.name}:${desktop.id}:${activity}`;

// KWin 6.7 reports its internal QML windows as Normal. isInternal() is not
// exposed to scripts; Qt's QObject string representation includes the exact
// metaobject class. Exclude these before touching their QWindow-backed getters.
const internalWindowClass = /^KWin::InternalWindow\(/;
const isInternalWindow = (window: KWinWindow): boolean =>
  internalWindowClass.test(String(window));

const isManageable = (window: KWinWindow): boolean => {
  if (
    isInternalWindow(window) ||
    window.deleted ||
    window.dock ||
    window.popupWindow ||
    window.specialWindow ||
    window.resourceClass === "plasmashell"
  ) {
    return false;
  }
  return (
    window.normalWindow !== false ||
    Boolean(window.dialog || window.splash || window.utility)
  );
};

const windowMetadata = (window: KWinWindow) => ({
  caption: String(window.caption ?? ""),
  dialog: window.dialog ?? false,
  fullScreen: window.fullScreen ?? false,
  maximized: (window.maximizeMode ?? 0) > 0,
  minimized: window.minimized ?? false,
  modal: window.modal ?? false,
  resizeable: window.resizeable ?? true,
  resourceClass: String(window.resourceClass ?? ""),
  resourceName: String(window.resourceName ?? ""),
  role: String(window.windowRole ?? ""),
  skipPager: window.skipPager ?? false,
  splash: window.splash ?? false,
  stackingOrder: window.stackingOrder ?? 0,
  transient: window.transient ?? false,
  utility: window.utility ?? false,
  ...(window.minSize === undefined
    ? {}
    : {
        minSize: { height: window.minSize.height, width: window.minSize.width },
      }),
  ...(window.maxSize === undefined
    ? {}
    : {
        maxSize: { height: window.maxSize.height, width: window.maxSize.width },
      }),
});

export interface KWinRuntime extends EngineRuntime {
  readonly reloadIfChanged: () => boolean;
}

const compositorError = (error: KWinApiError): CompositorError =>
  new CompositorError({
    cause: error.cause,
    operation: error.operation,
    target: error.target,
  });

/** Converts Qt object lifetimes and signals into platform-neutral Effect events. */
export const createRuntime = (api: KWinApi): KWinRuntime => {
  const report = (message: string): void => api.log(`KROHNKITE: ${message}`);
  const platform = runKWinSync(
    Effect.service(KWinScriptApi).pipe(
      Effect.provide(
        KWinScriptApi.layer(api, {
          onError: (error) =>
            report(formatCause(Cause.fail(compositorError(error)))),
        })
      )
    )
  );
  const { workspace } = platform.raw;
  const boundary = <A>(
    operation: string,
    thunk: () => A,
    target?: string
  ): Effect.Effect<A, CompositorError> =>
    platform
      .call(operation, thunk, target)
      .pipe(Effect.mapError(compositorError));
  const initialConfig = runKWinSyncExit(
    boundary("readConfig", () => readConfig(platform.raw.readConfig))
  );
  let config: Config = Exit.isSuccess(initialConfig)
    ? initialConfig.value
    : defaultConfig;
  let applying = false;
  let currentSend: ((event: EngineEvent) => void) | null = null;
  let lifetime: Scope.Scope | null = null;
  let previewArea: Rect = { height: 0, width: 0, x: 0, y: 0 };
  const known = new Map<string, KWinWindow>();
  const windowScopes = new Map<string, Scope.Closeable>();
  const originalDecorations = new Map<
    string,
    { noBorder: boolean; keepAbove: boolean; keepBelow: boolean }
  >();
  const originalMaximizeModes = new Map<string, number>();
  const originalMinimized = new Map<string, boolean>();

  const run = (effect: Effect.Effect<unknown, CompositorError>): void => {
    const exit = runKWinSyncExit(effect);
    if (Exit.isFailure(exit)) {
      report(formatCause(exit.cause));
    }
  };

  const desktopFor = (output: Output): VirtualDesktop =>
    workspace.currentDesktopForScreen?.(output) ??
    output.currentDesktop ??
    workspace.currentDesktop;
  const activeSurface = (): string => {
    const output = workspace.activeWindow?.output ?? workspace.activeScreen;
    return surfaceId(output, desktopFor(output), workspace.currentActivity);
  };

  const getSurfaces = (): Surface[] => {
    const surfaces: Surface[] = [];
    for (const output of workspace.screens) {
      const current = desktopFor(output);
      const desktops = workspace.desktops?.length
        ? workspace.desktops
        : [current];
      for (const desktop of desktops) {
        surfaces.push({
          desktop: desktop.id,
          id: surfaceId(output, desktop, workspace.currentActivity),
          screen: output.name,
          ...(desktop.name === undefined ? {} : { desktopName: desktop.name }),
          active: desktop.id === current.id,
          activity: workspace.currentActivity,
          area: rect(
            workspace.clientArea(api.kwin.PlacementArea, output, desktop)
          ),
        });
      }
    }
    return surfaces;
  };

  const snapshotWindow = (window: KWinWindow): ManagedWindow | null => {
    if (!isManageable(window)) {
      return null;
    }
    const output = window.output ?? workspace.activeScreen;
    // A destroyed Output wrapper must never be passed back to workspace.clientArea.
    if (!workspace.screens.some((screen) => screen.name === output.name)) {
      return null;
    }
    const currentDesktop = desktopFor(output);
    // Keep records for hidden desktops/activities, so their weights and float
    // toggles survive switching away. Only visible surfaces are arranged.
    const desktop =
      window.desktops?.find(
        (candidate) => candidate.id === currentDesktop.id
      ) ??
      window.desktops?.[0] ??
      currentDesktop;
    const activity = window.activities?.includes(workspace.currentActivity)
      ? workspace.currentActivity
      : (window.activities?.[0] ?? workspace.currentActivity);
    const geometry = rect(window.frameGeometry);
    if (geometry.width <= 0 || geometry.height <= 0) {
      return null;
    }
    return {
      ...windowMetadata(window),
      geometry,
      id: String(window.internalId),
      surfaceId: surfaceId(output, desktop, activity),
      visible:
        !window.hidden &&
        desktop.id === currentDesktop.id &&
        activity === workspace.currentActivity,
    };
  };

  const pruneWindows = (
    visible: ReadonlySet<string>,
    send: (event: EngineEvent) => void
  ): void => {
    const state = runtime.snapshot();
    for (const window of state?.windows ?? []) {
      if (!visible.has(window.id)) {
        send({ id: window.id, type: "remove" });
      }
    }
  };

  const refresh = (): Effect.Effect<void, CompositorError> =>
    boundary("snapshot", () => {
      if (applying || currentSend === null) {
        return;
      }
      currentSend({ surfaces: getSurfaces(), type: "surfaces" });
      const visible = new Set<string>();
      for (const window of known.values()) {
        const snapshot = snapshotWindow(window);
        if (snapshot !== null) {
          visible.add(snapshot.id);
          currentSend({ type: "upsert", window: snapshot });
        }
      }
      pruneWindows(visible, currentSend);
      const focused = workspace.activeWindow;
      currentSend({
        id: focused === null ? null : String(focused.internalId),
        type: "focus",
      });
    });

  const connect = <Args extends unknown[]>(
    signal: QtSignal<Args> | undefined,
    callback: (...args: Args) => void,
    target?: string
  ): Effect.Effect<void, CompositorError, Scope.Scope> =>
    platform
      .connect(signal, callback, target)
      .pipe(Effect.mapError(compositorError));

  const queryVirtualKeyboard = (
    id: string,
    corrected: () => void
  ): Effect.Effect<void, CompositorError> => {
    const parent = windowScopes.get(id);
    const query = api.queryVirtualKeyboard;
    if (parent === undefined || query === undefined) {
      return Effect.sync(corrected);
    }
    return Scope.provide(
      platform.queryVirtualKeyboard((visible) => {
        if (!visible && known.has(id) && currentSend !== null) {
          corrected();
        }
      }, id),
      parent
    ).pipe(Effect.mapError(compositorError));
  };

  const dragEvent = (
    window: KWinWindow,
    id: string,
    finished: boolean
  ): EngineEvent => {
    const pointer = workspace.cursorPos;
    return {
      finished,
      geometry: rect(window.frameGeometry),
      id,
      type: "drag",
      ...(pointer === undefined || pointer === null
        ? {}
        : { pointer: { x: pointer.x, y: pointer.y } }),
    };
  };

  const updateGeometry = (
    window: KWinWindow,
    id: string,
    changed: () => void
  ): void => {
    if (window.deleted || currentSend === null) {
      return;
    }
    if (window.move) {
      currentSend(dragEvent(window, id, false));
      return;
    }
    if (window.resize) {
      currentSend({
        finished: false,
        geometry: rect(window.frameGeometry),
        id,
        type: "resize",
      });
      return;
    }
    if (config.optVKeyboardSupport && api.queryVirtualKeyboard !== undefined) {
      run(queryVirtualKeyboard(id, changed));
    } else {
      changed();
    }
  };

  const bindWindow = (
    window: KWinWindow,
    id: string
  ): Effect.Effect<void, CompositorError, Scope.Scope> =>
    Effect.gen(function* () {
      const changed = () => run(refresh());
      let interaction: "move" | "resize" | null = null;
      if (window.resize) {
        interaction = "resize";
      } else if (window.move) {
        interaction = "move";
      }
      const finishInteraction = (): void => {
        if (window.deleted || currentSend === null) {
          return;
        }
        if (interaction === "resize") {
          currentSend({
            finished: true,
            geometry: rect(window.frameGeometry),
            id,
            type: "resize",
          });
        } else if (interaction === "move") {
          currentSend(dragEvent(window, id, true));
        }
        interaction = null;
      };
      const trackInteraction = (): void => {
        if (window.resize) {
          interaction = "resize";
        } else if (window.move) {
          interaction = "move";
        } else {
          finishInteraction();
        }
      };
      yield* connect(window.activitiesChanged, changed, id);
      yield* connect(window.desktopsChanged, changed, id);
      yield* connect(window.outputChanged, changed, id);
      yield* connect(window.fullScreenChanged, changed, id);
      yield* connect(window.hiddenChanged, changed, id);
      yield* connect(window.maximizedChanged, changed, id);
      yield* connect(
        window.maximizedAboutToChange,
        (mode) => {
          if (applying) {
            return;
          }
          run(
            boundary(
              "maximizeMode",
              () => {
                const snapshot = snapshotWindow(window);
                if (snapshot !== null) {
                  currentSend?.({
                    type: "upsert",
                    window: { ...snapshot, maximized: mode > 0 },
                  });
                }
              },
              id
            )
          );
        },
        id
      );
      yield* connect(
        window.minimizedChanged,
        () => {
          run(
            boundary(
              "minimizedChanged",
              () => {
                if (config.preventMinimize && window.minimized) {
                  window.minimized = false;
                  workspace.activeWindow = window;
                }
              },
              id
            )
          );
          changed();
        },
        id
      );
      yield* connect(window.skipPagerChanged, changed, id);
      yield* connect(window.captionChanged, changed, id);
      yield* connect(window.stackingOrderChanged, changed, id);
      const geometryChanged = () => {
        if (applying) {
          return;
        }
        if (window.resize) {
          interaction = "resize";
        } else if (window.move) {
          interaction = "move";
        }
        run(
          boundary(
            "geometryChanged",
            () => updateGeometry(window, id, changed),
            id
          )
        );
      };
      yield* connect(window.frameGeometryChanged, geometryChanged, id);
      // Some XWayland clients update the buffer before the frame.
      yield* connect(window.bufferGeometryChanged, geometryChanged, id);
      yield* connect(
        window.moveResizedChanged,
        () => {
          run(boundary("moveResize", trackInteraction, id));
          changed();
        },
        id
      );
      yield* connect(
        window.interactiveMoveResizeFinished,
        () => {
          run(boundary("dragFinished", finishInteraction, id));
          changed();
        },
        id
      );
    });

  const observeWindow = (
    window: KWinWindow
  ): Effect.Effect<void, CompositorError, Scope.Scope> =>
    Effect.gen(function* () {
      if (yield* boundary("windowType", () => isInternalWindow(window))) {
        return;
      }
      const id = yield* boundary("windowId", () => String(window.internalId));
      if (known.has(id)) {
        return;
      }
      const parent = yield* Effect.scope;
      const child = yield* Scope.fork(parent);
      windowScopes.set(id, child);
      known.set(id, window);
      yield* Scope.provide(bindWindow(window, id), child).pipe(
        Effect.onExit((exit) =>
          Exit.isFailure(exit)
            ? Effect.gen(function* () {
                yield* Scope.close(child, exit);
                windowScopes.delete(id);
                known.delete(id);
              })
            : Effect.void
        )
      );
    });

  const rememberDecorations = (id: string, window: KWinWindow): void => {
    if (!originalDecorations.has(id)) {
      originalDecorations.set(id, {
        keepAbove: window.keepAbove ?? false,
        keepBelow: window.keepBelow ?? false,
        noBorder: window.noBorder ?? false,
      });
    }
  };

  const applyGeometry = (window: KWinWindow, geometry: Rect): void => {
    if (window.move || window.resize) {
      return;
    }
    const adjusted = {
      ...rect(geometry),
      height: Math.min(
        window.maxSize?.height || Number.POSITIVE_INFINITY,
        Math.max(window.minSize?.height || 1, geometry.height)
      ),
      width: Math.min(
        window.maxSize?.width || Number.POSITIVE_INFINITY,
        Math.max(window.minSize?.width || 1, geometry.width)
      ),
    };
    if (!sameRect(window.frameGeometry, adjusted)) {
      window.frameGeometry = adjusted;
    }
  };

  const scheduleShortcutTimer = (
    deadline: number
  ): Effect.Effect<void, CompositorError> => {
    if (lifetime === null || api.scheduleTimer === undefined) {
      return Effect.void;
    }
    return Scope.provide(
      platform.scheduleTimer(Math.max(1, deadline - Date.now() + 5), () => {
        currentSend?.({ time: Date.now(), type: "shortcutTimeout" });
      }),
      lifetime
    ).pipe(Effect.mapError(compositorError));
  };

  const moveToSurface = (window: KWinWindow, id: string): void => {
    const target = getSurfaces().find((surface) => surface.id === id);
    if (target === undefined) {
      throw new Error(`Surface no longer exists: ${id}`);
    }
    const output = workspace.screens.find(
      (screen) => screen.name === target.screen
    );
    if (output === undefined) {
      throw new Error(`Output no longer exists: ${target.screen}`);
    }
    if (workspace.sendClientToScreen === undefined) {
      throw new Error("KWin sendClientToScreen is unavailable");
    }
    workspace.sendClientToScreen(window, output);
    const desktop =
      workspace.desktops?.find(
        (candidate) => candidate.id === target.desktop
      ) ?? desktopFor(output);
    window.desktops = [desktop];
  };

  const minimizeWindow = (
    id: string,
    window: KWinWindow,
    minimized: boolean
  ): void => {
    const original = window.minimized ?? false;
    if (original === minimized) {
      return;
    }
    if (!originalMinimized.has(id)) {
      originalMinimized.set(id, original);
    }
    window.minimized = minimized;
  };

  const maximizeWindow = (
    id: string,
    window: KWinWindow,
    maximized: boolean
  ): void => {
    const mode = window.maximizeMode ?? 0;
    if (window.setMaximize === undefined || mode === (maximized ? 3 : 0)) {
      return;
    }
    if (!originalMaximizeModes.has(id)) {
      originalMaximizeModes.set(id, mode);
    }
    window.setMaximize(maximized, maximized);
  };

  const restore = (
    id: string,
    thunk: (window: KWinWindow) => void
  ): Effect.Effect<void> =>
    boundary(
      "restore",
      () => {
        const window = known.get(id);
        if (window !== undefined && !window.deleted) {
          thunk(window);
        }
      },
      id
    ).pipe(
      Effect.catchTag("CompositorError", (error) =>
        Effect.sync(() => report(`restore ${id}: ${String(error.cause)}`))
      )
    );

  const mutateWindow = (
    command: Exclude<
      Command,
      { readonly type: "notify" | "shortcutTimer" | "dragPreview" }
    >,
    window: KWinWindow
  ): void => {
    switch (command.type) {
      case "geometry":
        applyGeometry(window, command.geometry);
        break;
      case "focus":
        if (workspace.activeWindow !== window) {
          workspace.activeWindow = window;
        }
        if (config.movePointerOnFocus) {
          api.movePointerToFocus?.();
        }
        break;
      case "border":
        rememberDecorations(command.id, window);
        window.noBorder = command.noBorder;
        break;
      case "layer":
        rememberDecorations(command.id, window);
        window.keepAbove = command.layer > 0;
        window.keepBelow = command.layer < 0;
        break;
      case "minimize":
        minimizeWindow(command.id, window, command.minimized);
        break;
      case "maximize":
        maximizeWindow(command.id, window, command.maximized);
        break;
      case "surface":
        moveToSurface(window, command.surfaceId);
        break;
      default: {
        const unexpected: never = command;
        throw new Error(`Unsupported command: ${String(unexpected)}`);
      }
    }
  };

  const apply = (command: Command): Effect.Effect<void, CompositorError> => {
    if (command.type === "shortcutTimer") {
      return scheduleShortcutTimer(command.deadline);
    }
    if (command.type === "dragPreview") {
      return boundary("dragPreview", () => {
        previewArea = command.area;
        api.preview?.(command.geometry, command.area);
      });
    }
    return boundary(
      command.type,
      () => {
        if (command.type === "notify") {
          if (config.notificationDuration > 0) {
            api.notify?.(command.message);
          }
          return;
        }
        const window = known.get(command.id);
        if (window === undefined || window.deleted) {
          return;
        }
        applying = true;
        try {
          mutateWindow(command, window);
        } finally {
          applying = false;
        }
      },
      command.type === "notify" ? undefined : command.id
    );
  };

  const host: HostService = {
    apply,
    observe: (send) =>
      Effect.gen(function* () {
        currentSend = send;
        yield* Effect.addFinalizer(() =>
          Effect.gen(function* () {
            currentSend = null;
            lifetime = null;
            yield* boundary("hideDragPreview", () =>
              api.preview?.(null, previewArea)
            ).pipe(
              Effect.catchTag("CompositorError", (error) =>
                Effect.sync(() =>
                  report(`hideDragPreview: ${String(error.cause)}`)
                )
              )
            );
            for (const [id, original] of originalDecorations) {
              yield* restore(id, (window) => {
                window.noBorder = original.noBorder;
                window.keepAbove = original.keepAbove;
                window.keepBelow = original.keepBelow;
              });
            }
            for (const [id, mode] of originalMaximizeModes) {
              yield* restore(id, (window) => {
                // KWin's vertical bit is 1; horizontal is 2.
                if ((window.maximizeMode ?? 0) !== mode) {
                  // biome-ignore lint/suspicious/noBitwiseOperators: KWin exposes maximizeMode as vertical/horizontal bit flags.
                  window.setMaximize?.((mode & 1) !== 0, (mode & 2) !== 0);
                }
              });
            }
            for (const [id, minimized] of originalMinimized) {
              yield* restore(id, (window) => {
                if (window.minimized !== minimized) {
                  window.minimized = minimized;
                }
              });
            }
            originalDecorations.clear();
            originalMaximizeModes.clear();
            originalMinimized.clear();
            windowScopes.clear();
            known.clear();
          })
        );
        // Callbacks share the acquired scope, including windows created after boot.
        const observerScope = yield* Effect.scope;
        lifetime = observerScope;
        yield* connect(workspace.windowAdded, (window) => {
          run(
            Effect.gen(function* () {
              yield* observeWindow(window);
              yield* refresh();
              yield* boundary("movePointer", () => {
                if (
                  config.movePointerOnFocus &&
                  workspace.activeWindow === window
                ) {
                  api.movePointerToCenter?.();
                }
              });
            }).pipe(Effect.provideService(Scope.Scope, observerScope))
          );
        });
        yield* connect(workspace.windowRemoved, (window) => {
          run(
            Effect.gen(function* () {
              const id = yield* boundary("removedWindowId", () =>
                String(window.internalId)
              );
              const child = windowScopes.get(id);
              if (child !== undefined) {
                yield* Scope.close(child, Exit.void);
              }
              windowScopes.delete(id);
              originalDecorations.delete(id);
              originalMaximizeModes.delete(id);
              originalMinimized.delete(id);
              known.delete(id);
              send({ id, type: "remove" });
              yield* refresh();
            })
          );
        });
        yield* connect(workspace.windowActivated, (window) => {
          run(
            boundary("windowActivated", () =>
              send({
                id: window === null ? null : String(window.internalId),
                type: "focus",
              })
            )
          );
        });
        const changed = () => run(refresh());
        yield* connect(workspace.screensChanged, changed);
        yield* connect(workspace.virtualScreenGeometryChanged, changed);
        yield* connect(workspace.currentDesktopChanged, changed);
        yield* connect(workspace.currentActivityChanged, changed);
        yield* connect(workspace.desktopsChanged, changed);
        yield* connect(workspace.activityRemoved, changed);
        for (const entry of api.shortcuts) {
          const action = shortcutActions[entry.name];
          if (action !== undefined) {
            yield* connect(entry.hdl.activated, () => {
              run(
                boundary(
                  "shortcut",
                  () =>
                    send({
                      action,
                      shortcut: entry.name,
                      surfaceId: activeSurface(),
                      time: Date.now(),
                      type: "action",
                    }),
                  entry.name
                )
              );
            });
          }
        }
        const windows = yield* boundary("stackingOrder", () => [
          ...workspace.stackingOrder,
        ]);
        for (const window of windows) {
          yield* observeWindow(window);
        }
        yield* refresh();
      }),
    report,
  };

  const runtime = createEngineRuntime(config, host);
  return {
    ...runtime,
    reloadIfChanged: () => {
      if (!runtime.isRunning()) {
        return false;
      }
      const loaded = runKWinSyncExit(
        boundary("readConfig", () => readConfig(api.readConfig))
      );
      if (Exit.isFailure(loaded)) {
        report(formatCause(loaded.cause));
        return false;
      }
      if (JSON.stringify(config) === JSON.stringify(loaded.value)) {
        return false;
      }
      const previous = config;
      config = loaded.value;
      if (runtime.configure(config)) {
        run(refresh());
        report("configuration reloaded");
        return true;
      }
      config = previous;
      runtime.configure(previous);
      return false;
    },
    start: () => {
      if (Exit.isFailure(initialConfig)) {
        report(formatCause(initialConfig.cause));
        return false;
      }
      return runtime.start();
    },
  };
};
