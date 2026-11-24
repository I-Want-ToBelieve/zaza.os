import { assert, it, vi } from "@effect/vitest";
import { shortcutActions } from "@krohnkite/config";
import type { Rect } from "@krohnkite/core";
import * as Effect from "effect/Effect";
import * as Scheduler from "effect/Scheduler";
import {
  createRuntime,
  type KWinApi,
  type KWinWindow,
  type Output,
  type QtSignal,
  type VirtualDesktop,
  type Workspace,
} from "./index.ts";

class Signal<Args extends unknown[] = []> implements QtSignal<Args> {
  readonly callbacks = new Set<(...args: Args) => void>();
  readonly connect = (callback: (...args: Args) => void): void => {
    this.callbacks.add(callback);
  };
  readonly disconnect = (callback: (...args: Args) => void): void => {
    this.callbacks.delete(callback);
  };
  readonly emit = (...args: Args): void => {
    for (const callback of [...this.callbacks]) {
      callback(...args);
    }
  };
}

const desktop: VirtualDesktop = { id: "desktop-1", name: "One" };
const otherDesktop: VirtualDesktop = { id: "desktop-2", name: "Two" };
const output: Output = {
  geometry: { height: 800, width: 1200, x: 0, y: 0 },
  name: "monitor-1",
};

class Window implements KWinWindow {
  readonly internalId: string;
  readonly normalWindow = true;
  readonly resourceClass = "kitty";
  readonly caption = "Terminal";
  readonly windowRole = "";
  output: Output = output;
  desktops: readonly VirtualDesktop[] = [desktop];
  readonly activities: readonly string[] = [];
  minimized = false;
  noBorder = false;
  keepAbove = false;
  keepBelow = false;
  fullScreen = false;
  maximizeMode = 0;
  readonly maximizeCalls: [boolean, boolean][] = [];
  move = false;
  resize = false;
  hidden = false;
  deleted = false;
  writes = 0;
  readonly frameGeometryChanged = new Signal();
  readonly bufferGeometryChanged = new Signal();
  readonly desktopsChanged = new Signal();
  readonly activitiesChanged = new Signal();
  readonly outputChanged = new Signal();
  readonly fullScreenChanged = new Signal();
  readonly hiddenChanged = new Signal();
  readonly maximizedChanged = new Signal();
  readonly maximizedAboutToChange = new Signal<[number]>();
  readonly minimizedChanged = new Signal();
  readonly moveResizedChanged = new Signal();
  readonly interactiveMoveResizeFinished = new Signal();
  private geometry: Rect = { height: 300, width: 400, x: 50, y: 60 };
  constructor(internalId: string) {
    this.internalId = internalId;
  }
  get frameGeometry(): Rect {
    return this.geometry;
  }
  set frameGeometry(value: Rect) {
    this.geometry = value;
    this.writes += 1;
    this.frameGeometryChanged.emit();
  }
  readonly setMaximize = (vertically: boolean, horizontally: boolean): void => {
    this.maximizeCalls.push([vertically, horizontally]);
    this.maximizeMode = (vertically ? 1 : 0) + (horizontally ? 2 : 0);
    this.maximizedChanged.emit();
  };
  get connections(): number {
    return (
      this.frameGeometryChanged.callbacks.size +
      this.bufferGeometryChanged.callbacks.size +
      this.desktopsChanged.callbacks.size +
      this.activitiesChanged.callbacks.size +
      this.outputChanged.callbacks.size +
      this.fullScreenChanged.callbacks.size +
      this.hiddenChanged.callbacks.size +
      this.maximizedChanged.callbacks.size +
      this.maximizedAboutToChange.callbacks.size +
      this.minimizedChanged.callbacks.size +
      this.moveResizedChanged.callbacks.size +
      this.interactiveMoveResizeFinished.callbacks.size
    );
  }
}

class Compositor implements Workspace {
  screens: readonly Output[] = [output];
  activeScreen = output;
  currentDesktop = desktop;
  currentActivity = "activity";
  readonly desktops = [desktop, otherDesktop];
  stackingOrder: Window[] = [new Window("one"), new Window("two")];
  readonly windowAdded = new Signal<[KWinWindow]>();
  readonly windowRemoved = new Signal<[KWinWindow]>();
  readonly windowActivated = new Signal<[KWinWindow | null]>();
  readonly screensChanged = new Signal();
  readonly virtualScreenGeometryChanged = new Signal();
  readonly currentDesktopChanged = new Signal<[VirtualDesktop]>();
  readonly currentActivityChanged = new Signal<[string]>();
  private active: KWinWindow | null = this.stackingOrder[0] ?? null;
  get activeWindow(): KWinWindow | null {
    return this.active;
  }
  set activeWindow(window: KWinWindow | null) {
    this.active = window;
    this.windowActivated.emit(window);
  }
  readonly clientArea = (_option: number, screen: Output): Rect =>
    screen.geometry ?? { height: 800, width: 1200, x: 0, y: 0 };
  readonly currentDesktopForScreen = (): VirtualDesktop => this.currentDesktop;
  readonly sendClientToScreen = (window: KWinWindow, screen: Output): void => {
    if (window instanceof Window) {
      window.output = screen;
      window.outputChanged.emit();
    }
  };
}

const fixture = (extensions: Partial<KWinApi> = {}) => {
  const workspace = new Compositor();
  const reports: string[] = [];
  const shortcuts = {
    float: new Signal(),
    layout: new Signal(),
    next: new Signal(),
  };
  const overrides = new Map<string, unknown>();
  const api: KWinApi = {
    kwin: { PlacementArea: 0 },
    log: (message) => {
      reports.push(message);
    },
    readConfig: (name, fallback) => overrides.get(name) ?? fallback,
    shortcuts: [
      { hdl: { activated: shortcuts.next }, name: "FocusNextSC" },
      { hdl: { activated: shortcuts.float }, name: "ToggleFloatSC" },
      { hdl: { activated: shortcuts.layout }, name: "SetMonocleLayoutSC" },
    ],
    workspace,
    ...extensions,
  };
  return {
    api,
    overrides,
    reports,
    runtime: createRuntime(api),
    shortcuts,
    workspace,
  };
};

const scopedFixture = (extensions: Partial<KWinApi> = {}) =>
  Effect.gen(function* () {
    const result = fixture(extensions);
    yield* Effect.addFinalizer(() =>
      Effect.sync(() => result.runtime.dispose())
    );
    return result;
  });

it("39 shortcuts and twelve windows complete their lifecycle without scheduling", () => {
  const shortcuts = Object.keys(shortcutActions).map((name) => ({
    hdl: { activated: new Signal() },
    name,
  }));
  const { workspace, runtime, overrides, reports } = fixture({ shortcuts });
  workspace.stackingOrder = Array.from(
    { length: 12 },
    (_, index) => new Window(`window-${index}`)
  );
  workspace.activeWindow = workspace.stackingOrder[0] ?? null;
  const shouldYield = vi.spyOn(
    Scheduler.MixedScheduler.prototype,
    "shouldYield"
  );
  try {
    assert.equal(shortcuts.length, 39);
    assert.equal(runtime.start(), true);
    assert.equal(runtime.snapshot()?.windows.length, 12);
    assert.ok(
      shortcuts.every((entry) => entry.hdl.activated.callbacks.size === 1)
    );
    const [first, second] = workspace.stackingOrder;
    assert.ok(first && second);
    first.hidden = true;
    first.hiddenChanged.emit();
    first.hidden = false;
    first.hiddenChanged.emit();
    const monocle = shortcuts.find(
      (entry) => entry.name === "SetMonocleLayoutSC"
    );
    const tile = shortcuts.find((entry) => entry.name === "SetTileLayoutSC");
    assert.ok(monocle && tile);
    monocle.hdl.activated.emit();
    assert.equal(first.maximizeMode, 3);
    tile.hdl.activated.emit();
    assert.equal(first.maximizeMode, 0);
    const added = new Window("later-window");
    workspace.stackingOrder.push(added);
    workspace.windowAdded.emit(added);
    assert.equal(runtime.snapshot()?.windows.length, 13);
    overrides.set("screenGapLeft", "16");
    assert.equal(runtime.reloadIfChanged(), true);
    assert.equal(first.frameGeometry.x, 16);
    assert.equal(runtime.snapshot()?.windows.length, 13);
    runtime.dispose();
    assert.ok(
      workspace.stackingOrder.every((window) => window.connections === 0)
    );
    assert.ok(
      shortcuts.every((entry) => entry.hdl.activated.callbacks.size === 0)
    );
    assert.equal(workspace.windowAdded.callbacks.size, 0);
    assert.equal(shouldYield.mock.calls.length, 0);
    assert.deepEqual(reports, ["KROHNKITE: configuration reloaded"]);
  } finally {
    runtime.dispose();
    shouldYield.mockRestore();
  }
});

it.effect(
  "Qt observer tiles, focuses with stable shortcut names, and disposes listeners",
  () =>
    Effect.gen(function* () {
      const { workspace, runtime, reports, shortcuts } = yield* scopedFixture();
      assert.equal(runtime.start(), true);
      const [first, second] = workspace.stackingOrder;
      assert.ok(first && second);
      assert.ok(
        first.frameGeometry.width > 0 && second.frameGeometry.width > 0
      );
      assert.ok(
        first.frameGeometry.x + first.frameGeometry.width <=
          second.frameGeometry.x
      );
      assert.ok(first.connections > 0);
      assert.ok(
        first.writes < 20,
        "geometry callback must not re-enter arrangement indefinitely"
      );
      shortcuts.next.emit();
      assert.equal(workspace.activeWindow, second);
      runtime.dispose();
      assert.equal(first.connections, 0);
      assert.equal(second.connections, 0);
      assert.equal(workspace.windowAdded.callbacks.size, 0);
      assert.equal(shortcuts.next.callbacks.size, 0);
      assert.equal(first.noBorder, false);
      assert.deepEqual(reports, []);
    })
);

it.effect(
  "removed windows release their individual scopes while workspace remains live",
  () =>
    Effect.gen(function* () {
      const { workspace, runtime } = yield* scopedFixture();
      runtime.start();
      const removed = workspace.stackingOrder.shift();
      assert.ok(removed);
      workspace.windowRemoved.emit(removed);
      assert.equal(removed.connections, 0);
      assert.equal(
        runtime
          .snapshot()
          ?.windows.some((window) => window.id === removed.internalId),
        false
      );
      assert.equal(workspace.windowAdded.callbacks.size, 1);
      const added = new Window("three");
      workspace.stackingOrder.push(added);
      workspace.windowAdded.emit(added);
      assert.ok(added.connections > 0);
      assert.equal(
        runtime.snapshot()?.windows.some((window) => window.id === "three"),
        true
      );
      runtime.dispose();
      assert.equal(added.connections, 0);
    })
);

it.effect(
  "hidden-only signals restore two-window tiling and disconnect on disposal",
  () =>
    Effect.gen(function* () {
      const { workspace, runtime, reports } = yield* scopedFixture();
      const [first, second] = workspace.stackingOrder;
      assert.ok(first && second);
      first.hidden = true;
      const hiddenGeometry = { ...first.frameGeometry };
      assert.equal(runtime.start(), true);
      assert.deepEqual(first.frameGeometry, hiddenGeometry);
      assert.equal(second.frameGeometry.width, output.geometry?.width);
      assert.equal(
        runtime.snapshot()?.windows.find((window) => window.id === "one")
          ?.visible,
        false
      );
      assert.equal(first.hiddenChanged.callbacks.size, 1);

      first.hidden = false;
      first.hiddenChanged.emit();
      assert.equal(runtime.snapshot()?.windows.length, 2);
      assert.equal(
        runtime.snapshot()?.windows.find((window) => window.id === "one")
          ?.visible,
        true
      );
      assert.ok(
        first.frameGeometry.x + first.frameGeometry.width <=
          second.frameGeometry.x
      );
      assert.ok(second.frameGeometry.width < (output.geometry?.width ?? 0));

      second.hidden = true;
      second.hiddenChanged.emit();
      assert.equal(first.frameGeometry.width, output.geometry?.width);
      second.hidden = false;
      second.hiddenChanged.emit();
      assert.equal(
        runtime.snapshot()?.windows.find((window) => window.id === "two")
          ?.visible,
        true
      );
      assert.ok(
        first.frameGeometry.x + first.frameGeometry.width <=
          second.frameGeometry.x
      );

      runtime.dispose();
      assert.equal(first.hiddenChanged.callbacks.size, 0);
      assert.equal(second.hiddenChanged.callbacks.size, 0);
      const firstWrites = first.writes;
      const secondWrites = second.writes;
      first.hidden = true;
      first.hiddenChanged.emit();
      assert.equal(first.writes, firstWrites);
      assert.equal(second.writes, secondWrites);
      assert.deepEqual(reports, []);
    })
);

it.effect(
  "internal QML notifications never enter tiling or read QWindow-backed properties",
  () =>
    Effect.gen(function* () {
      let unsafeReads = 0;
      const initialPopup = new Window("initial-notification");
      const popup = new Window("layout-notification");
      for (const internal of [initialPopup, popup]) {
        Object.defineProperties(internal, {
          maxSize: {
            get: () => {
              unsafeReads += 1;
              throw new Error("Deleted internal QWindow maximumSize");
            },
          },
          minSize: {
            get: () => {
              unsafeReads += 1;
              throw new Error("Deleted internal QWindow minimumSize");
            },
          },
          resourceClass: { value: "" },
          toString: {
            value: () => 'KWin::InternalWindow(0x1234, "notification")',
          },
        });
      }
      const { workspace, runtime, shortcuts, reports } = yield* scopedFixture({
        notify: () => {
          if (!workspace.stackingOrder.includes(popup)) {
            workspace.stackingOrder.push(popup);
            workspace.windowAdded.emit(popup);
          }
        },
      });
      workspace.stackingOrder.push(initialPopup);
      assert.equal(runtime.start(), true);
      assert.equal(runtime.snapshot()?.windows.length, 2);
      assert.equal(initialPopup.connections, 0);
      shortcuts.layout.emit();
      assert.equal(popup.connections, 0);
      assert.equal(runtime.snapshot()?.windows.length, 2);
      runtime.send({ action: "layout:tile", type: "action" });
      const [first, second] = workspace.stackingOrder;
      assert.ok(first && second);
      assert.equal(first.frameGeometry.height, output.geometry?.height);
      assert.equal(second.frameGeometry.height, output.geometry?.height);
      assert.ok(
        first.frameGeometry.x + first.frameGeometry.width <=
          second.frameGeometry.x
      );
      workspace.stackingOrder.splice(workspace.stackingOrder.indexOf(popup), 1);
      workspace.windowRemoved.emit(popup);
      assert.equal(runtime.snapshot()?.windows.length, 2);
      runtime.dispose();
      assert.equal(first.connections, 0);
      assert.equal(second.connections, 0);
      assert.equal(unsafeReads, 0);
      assert.deepEqual(reports, []);
    })
);

it.effect("ordinary windows with an empty resource class remain managed", () =>
  Effect.gen(function* () {
    const { workspace, runtime, reports } = yield* scopedFixture();
    const [first, second] = workspace.stackingOrder;
    assert.ok(first && second);
    Object.defineProperty(second, "resourceClass", { value: "" });
    assert.equal(runtime.start(), true);
    assert.equal(runtime.snapshot()?.windows.length, 2);
    assert.ok(second.connections > 0);
    assert.ok(
      first.frameGeometry.x + first.frameGeometry.width <=
        second.frameGeometry.x
    );
    assert.equal(second.frameGeometry.height, output.geometry?.height);
    assert.deepEqual(reports, []);
  })
);

it.effect(
  "desktop switches retain manual float state and do not tile hidden windows",
  () =>
    Effect.gen(function* () {
      const { workspace, runtime, shortcuts } = yield* scopedFixture();
      runtime.start();
      const [first] = workspace.stackingOrder;
      assert.ok(first);
      shortcuts.float.emit();
      assert.equal(
        runtime.snapshot()?.windows.find((window) => window.id === "one")
          ?.floating,
        true
      );
      workspace.currentDesktop = otherDesktop;
      const { writes } = first;
      workspace.currentDesktopChanged.emit(otherDesktop);
      assert.equal(first.writes, writes);
      assert.equal(
        runtime.snapshot()?.windows.find((window) => window.id === "one")
          ?.floating,
        true
      );
      workspace.currentDesktop = desktop;
      workspace.currentDesktopChanged.emit(desktop);
      assert.equal(
        runtime.snapshot()?.windows.find((window) => window.id === "one")
          ?.floating,
        true
      );
      runtime.dispose();
    })
);

it.effect(
  "configuration reload applies new settings and leaves callback counts stable",
  () =>
    Effect.gen(function* () {
      const { workspace, runtime, overrides } = yield* scopedFixture();
      runtime.start();
      const [first] = workspace.stackingOrder;
      assert.ok(first);
      const before = first.connections;
      assert.equal(runtime.reloadIfChanged(), false);
      overrides.set("screenGapLeft", 24);
      assert.equal(runtime.reloadIfChanged(), true);
      assert.equal(first.frameGeometry.x, 24);
      assert.equal(first.connections, before);
      assert.equal(runtime.reloadIfChanged(), false);
      runtime.dispose();
    })
);

it.effect(
  "partial KConfig read failures keep the previous configuration and recover on the next reload",
  () =>
    Effect.gen(function* () {
      const entries = new Map<string, unknown>([["screenGapLeft", "8"]]);
      const failingKeys = new Set<string>();
      let reads = 0;
      const { workspace, runtime, reports } = yield* scopedFixture({
        readConfig: (name, fallback) => {
          reads += 1;
          if (failingKeys.has(name)) {
            throw new Error("KConfig read unavailable");
          }
          return entries.get(name) ?? fallback;
        },
      });
      assert.equal(runtime.start(), true);
      const [first] = workspace.stackingOrder;
      assert.ok(first);
      const initialState = runtime.snapshot();
      const initialGeometry = { ...first.frameGeometry };
      const { connections } = first;
      entries.set("screenGapLeft", "24");
      failingKeys.add("screenGapTop");
      assert.equal(runtime.reloadIfChanged(), false);
      assert.deepEqual(runtime.snapshot(), initialState);
      assert.deepEqual(first.frameGeometry, initialGeometry);
      assert.equal(first.connections, connections);
      assert.equal(reports.length, 1);
      assert.ok(reports[0]?.includes("readConfig"));
      assert.ok(reports[0]?.includes("KConfig read unavailable"));
      failingKeys.clear();
      assert.equal(runtime.reloadIfChanged(), true);
      assert.equal(first.frameGeometry.x, 24);
      assert.equal(first.connections, connections);
      assert.equal(runtime.reloadIfChanged(), false);
      entries.delete("screenGapLeft");
      assert.equal(runtime.reloadIfChanged(), true);
      assert.equal(first.frameGeometry.x, 0);
      runtime.dispose();
      const previousReads = reads;
      assert.equal(runtime.reloadIfChanged(), false);
      assert.equal(reads, previousReads);
    })
);

it.effect(
  "configuration reload reclassifies live windows without losing manual float choices",
  () =>
    Effect.gen(function* () {
      const { workspace, runtime, overrides, shortcuts } =
        yield* scopedFixture();
      assert.equal(runtime.start(), true);
      const [first, second] = workspace.stackingOrder;
      assert.ok(first && second);
      shortcuts.float.emit();
      const manuallyFloating = runtime
        .snapshot()
        ?.windows.find((window) => window.id === first.internalId);
      assert.equal(manuallyFloating?.manualFloating, true);
      overrides.set("floatingClass", "kitty");
      assert.equal(runtime.reloadIfChanged(), true);
      assert.equal(
        runtime
          .snapshot()
          ?.windows.find((window) => window.id === second.internalId)?.floating,
        true
      );
      overrides.set("floatingClass", "");
      assert.equal(runtime.reloadIfChanged(), true);
      assert.equal(
        runtime
          .snapshot()
          ?.windows.find((window) => window.id === first.internalId)?.floating,
        true
      );
      assert.equal(
        runtime
          .snapshot()
          ?.windows.find((window) => window.id === second.internalId)?.floating,
        false
      );
      overrides.set("ignoreClass", "kitty");
      assert.equal(runtime.reloadIfChanged(), true);
      second.frameGeometry = { ...second.frameGeometry, width: 233, x: 73 };
      const { writes } = second;
      runtime.send({ type: "arrange" });
      assert.equal(second.writes, writes);
      overrides.set("ignoreClass", "");
      assert.equal(runtime.reloadIfChanged(), true);
      assert.ok(second.writes > writes);
    })
);

it.effect("fullscreen windows keep their compositor geometry", () =>
  Effect.gen(function* () {
    const { workspace, runtime } = yield* scopedFixture();
    const [first] = workspace.stackingOrder;
    assert.ok(first);
    first.fullScreen = true;
    const initial = first.frameGeometry;
    runtime.start();
    assert.deepEqual(first.frameGeometry, initial);
    first.fullScreen = false;
    first.fullScreenChanged.emit();
    assert.ok(first.writes > 0);
    runtime.dispose();
  })
);

it.effect(
  "file configuration can disable notifications and enable them on reload",
  () =>
    Effect.gen(function* () {
      const notifications: string[] = [];
      const { runtime, overrides, shortcuts } = yield* scopedFixture({
        notify: (message) => {
          notifications.push(message);
        },
      });
      overrides.set("notificationDuration", "0");
      assert.equal(runtime.start(), true);
      assert.equal(runtime.reloadIfChanged(), true);
      shortcuts.layout.emit();
      assert.deepEqual(notifications, []);
      overrides.set("notificationDuration", "500");
      assert.equal(runtime.reloadIfChanged(), true);
      runtime.send({ action: "layout:tile", type: "action" });
      assert.deepEqual(notifications, ["Tile"]);
      overrides.set("notificationDuration", "-10");
      assert.equal(runtime.reloadIfChanged(), true);
      runtime.send({ action: "layout:monocle", type: "action" });
      assert.deepEqual(notifications, ["Tile"]);
      overrides.delete("notificationDuration");
      assert.equal(runtime.reloadIfChanged(), true);
      runtime.send({ action: "floatAll", type: "action" });
      assert.deepEqual(notifications, ["Tile", "Float All"]);
    })
);

it.effect(
  "shortcut fallback timers close after firing and cancel on runtime disposal",
  () =>
    Effect.gen(function* () {
      const timers: {
        callback: () => void;
        delay: number;
        canceled: boolean;
      }[] = [];
      const { workspace, runtime } = yield* scopedFixture({
        readConfig: (name, fallback) =>
          name === "shortcutConf"
            ? "FocusNextSC,FocusNextSC:ma=ToggleFloatAll,st=40"
            : fallback,
        scheduleTimer: (delay, callback) => {
          const timer = { callback, canceled: false, delay };
          timers.push(timer);
          return () => {
            timer.canceled = true;
          };
        },
      });
      assert.equal(runtime.start(), true);
      runtime.send({
        action: "focusNext",
        shortcut: "FocusNextSC",
        time: Date.now() - 1000,
        type: "action",
      });
      const [expired] = timers;
      assert.ok(expired);
      assert.equal(expired.delay, 1);
      assert.equal(workspace.activeWindow?.internalId, "one");
      expired.callback();
      assert.equal(workspace.activeWindow?.internalId, "two");
      assert.equal(expired.canceled, true);
      runtime.send({
        action: "focusNext",
        shortcut: "FocusNextSC",
        time: Date.now(),
        type: "action",
      });
      const [, pending] = timers;
      assert.ok(pending);
      assert.equal(pending.canceled, false);
      runtime.dispose();
      assert.equal(pending.canceled, true);
    })
);

it.effect(
  "virtual keyboard queries defer correction and are released with their window",
  () =>
    Effect.gen(function* () {
      const queries: {
        callback: (visible: boolean) => void;
        canceled: boolean;
      }[] = [];
      const { workspace, runtime, reports } = yield* scopedFixture({
        queryVirtualKeyboard: (callback) => {
          const query = { callback, canceled: false };
          queries.push(query);
          return () => {
            query.canceled = true;
          };
        },
        readConfig: (name, fallback) =>
          name === "optVKeyboardSupport" ? true : fallback,
      });
      runtime.start();
      const [first] = workspace.stackingOrder;
      assert.ok(first);
      const initial = { ...first.frameGeometry };
      first.frameGeometry = { ...initial, width: initial.width - 100 };
      const [visibleQuery] = queries;
      assert.ok(visibleQuery);
      visibleQuery.callback(true);
      assert.equal(first.frameGeometry.width, initial.width - 100);
      assert.equal(visibleQuery.canceled, true);
      first.frameGeometry = { ...initial, width: initial.width - 200 };
      const [, hiddenQuery] = queries;
      assert.ok(hiddenQuery);
      hiddenQuery.callback(false);
      assert.deepEqual(first.frameGeometry, initial);
      assert.equal(hiddenQuery.canceled, true);
      first.frameGeometry = { ...initial, width: initial.width - 100 };
      const [, , pendingQuery] = queries;
      assert.ok(pendingQuery);
      workspace.stackingOrder.shift();
      workspace.windowRemoved.emit(first);
      assert.equal(pendingQuery.canceled, true);
      runtime.dispose();
      assert.deepEqual(reports, []);
    })
);

it.effect("drag previews are cleared when the script is disposed", () =>
  Effect.gen(function* () {
    const previews: { geometry: Rect | null; area: Rect }[] = [];
    const { runtime } = yield* scopedFixture({
      preview: (geometry, area) => previews.push({ area, geometry }),
    });
    runtime.start();
    runtime.dispose();
    const [last] = previews.slice(-1);
    assert.ok(last);
    assert.equal(last.geometry, null);
  })
);

it.effect(
  "interactive resize applies at completion when live adjustment is disabled",
  () =>
    Effect.gen(function* () {
      const { runtime, workspace } = yield* scopedFixture({
        readConfig: (name, fallback) =>
          name === "adjustLayoutLive" ? false : fallback,
      });
      runtime.start();
      const [first] = workspace.stackingOrder;
      assert.ok(first);
      const before = runtime.snapshot();
      assert.ok(before);
      const [layout] = Object.values(before.layouts);
      assert.ok(layout);
      first.resize = true;
      first.moveResizedChanged.emit();
      first.frameGeometry = {
        ...first.frameGeometry,
        width: first.frameGeometry.width + 60,
      };
      assert.equal(
        runtime.snapshot()?.layouts[Object.keys(before.layouts)[0] ?? ""]
          ?.ratio,
        layout.ratio
      );
      first.resize = false;
      first.moveResizedChanged.emit();
      const after = runtime.snapshot();
      assert.ok(after);
      const [resized] = Object.values(after.layouts);
      assert.ok(resized);
      assert.ok(resized.ratio > layout.ratio);
      first.interactiveMoveResizeFinished.emit();
      assert.deepEqual(runtime.snapshot()?.layouts, after.layouts);
      runtime.dispose();
    })
);

it.effect(
  "unloading Monocle restores owned maximization so the next runtime can tile",
  () =>
    Effect.gen(function* () {
      const { api, runtime, workspace, shortcuts, reports } =
        yield* scopedFixture();
      runtime.start();
      const [first, second] = workspace.stackingOrder;
      assert.ok(first && second);
      shortcuts.layout.emit();
      assert.equal(first.maximizeMode, 3);
      assert.equal(second.maximizeMode, 3);
      runtime.dispose();
      assert.equal(first.maximizeMode, 0);
      assert.equal(second.maximizeMode, 0);
      const reloaded = createRuntime(api);
      yield* Effect.addFinalizer(() => Effect.sync(() => reloaded.dispose()));
      assert.equal(reloaded.start(), true);
      assert.ok(
        first.frameGeometry.x + first.frameGeometry.width <=
          second.frameGeometry.x
      );
      reloaded.dispose();
      assert.deepEqual(reports, []);
    })
);

it.effect(
  "unloading restores only the minimization changed by layout commands",
  () =>
    Effect.gen(function* () {
      const { runtime, workspace, shortcuts } = yield* scopedFixture({
        readConfig: (name, fallback) => {
          if (name === "monocleMinimizeRest") {
            return true;
          }
          if (name === "preventMinimize") {
            return false;
          }
          return fallback;
        },
      });
      const untouched = new Window("manually-minimized");
      untouched.minimized = true;
      workspace.stackingOrder.push(untouched);
      runtime.start();
      const [first, second] = workspace.stackingOrder;
      assert.ok(first && second);
      shortcuts.layout.emit();
      assert.equal(second.minimized, true);
      runtime.dispose();
      assert.equal(first.minimized, false);
      assert.equal(second.minimized, false);
      assert.equal(untouched.minimized, true);
    })
);

for (const mode of [1, 2]) {
  it.effect(
    `unloading preserves the axes of original partial maximization mode ${mode}`,
    () =>
      Effect.gen(function* () {
        const { runtime, workspace, shortcuts } = yield* scopedFixture();
        const [first] = workspace.stackingOrder;
        assert.ok(first);
        first.maximizeMode = mode;
        runtime.start();
        shortcuts.layout.emit();
        assert.equal(first.maximizeMode, mode);
        // Qt emits this before changing the actual maximizeMode property. The
        // Monocle command therefore replaces an existing partial maximization.
        first.maximizedAboutToChange.emit(0);
        assert.equal(first.maximizeMode, 3);
        runtime.dispose();
        assert.equal(first.maximizeMode, mode);
        assert.deepEqual(first.maximizeCalls, [
          [true, true],
          [mode === 1, mode === 2],
        ]);
      })
  );
}

it.effect(
  "removed window state cannot affect a later window reusing the same ID",
  () =>
    Effect.gen(function* () {
      const { runtime, workspace, shortcuts } = yield* scopedFixture();
      runtime.start();
      const removed = workspace.stackingOrder.shift();
      assert.ok(removed);
      shortcuts.layout.emit();
      // The observer still knows this window until the compositor removes it.
      assert.equal(removed.maximizeMode, 3);
      removed.deleted = true;
      workspace.windowRemoved.emit(removed);
      const replacement = new Window(removed.internalId);
      replacement.maximizeMode = 2;
      replacement.minimized = true;
      workspace.stackingOrder.push(replacement);
      workspace.windowAdded.emit(replacement);
      runtime.dispose();
      assert.equal(replacement.maximizeMode, 2);
      assert.equal(replacement.minimized, true);
    })
);
