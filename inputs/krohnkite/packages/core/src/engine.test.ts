import { type Config, defaultConfig, layoutIds } from "@krohnkite/config";
import { expect, it } from "vitest";
import {
  arrangeLayout,
  createState,
  type EngineEvent,
  type EngineState,
  getGaps,
  type ManagedWindow,
  reduce,
  type Surface,
  sameRect,
  split,
  surfaceKey,
} from "./index.js";

const surface: Surface = {
  activity: "work",
  area: { height: 1050, width: 1920, x: 0, y: 30 },
  desktop: "1",
  desktopName: "Desktop 1",
  id: "display:1",
  screen: "DP-1",
};
const window = (
  id: string,
  extra: Partial<ManagedWindow> = {}
): ManagedWindow => ({
  caption: id,
  geometry: { height: 400, width: 600, x: 50, y: 60 },
  id,
  resourceClass: "kitty",
  role: "",
  surfaceId: surface.id,
  ...extra,
});
function setup(count = 2, config: Config = defaultConfig): EngineState {
  let { state } = reduce(
    createState(),
    { surfaces: [surface], type: "surfaces" },
    config
  );
  for (let index = 0; index < count; index += 1) {
    ({ state } = reduce(
      state,
      { type: "upsert", window: window(String(index)) },
      config
    ));
  }
  return reduce(state, { id: "0", type: "focus" }, config).state;
}
function send(
  state: EngineState,
  event: EngineEvent,
  config: Config = defaultConfig
): EngineState {
  return reduce(state, event, config).state;
}
it("tile uses the available area and exact between and screen gaps", () => {
  const config = {
    ...defaultConfig,
    screenGapBetween: 8,
    screenGapBottom: 8,
    screenGapLeft: 8,
    screenGapRight: 8,
    screenGapTop: 8,
  };
  const state = setup(2, config);
  expect(state.windows.map((entry) => entry.geometry)).toStrictEqual([
    { height: 1034, width: 948, x: 8, y: 38 },
    { height: 1034, width: 948, x: 964, y: 38 },
  ]);
});
it("weighted splitting retains integer endpoints on odd spans", () => {
  const rects = split(
    { height: 600, width: 1001, x: 0, y: 0 },
    [1, 2, 3],
    5,
    true
  );
  expect(rects[2] ? rects[2].x + rects[2].width : 0).toBe(1001);
  expect(rects[1]?.x).toBe((rects[0]?.width ?? 0) + 5);
});
for (const id of layoutIds) {
  it(`${id} produces valid geometry for its layout family`, () => {
    const config = {
      ...defaultConfig,
      srfExceededToScreen: false,
      srfExceededToVDesktop: false,
    };
    const state = send(
      setup(8, config),
      { action: `layout:${id}`, type: "action" },
      config
    );
    const layout = state.layouts[surfaceKey(surface, config)];
    expect(layout).toBeTruthy();
    if (layout === undefined) {
      throw new Error("Expected layout to be defined");
    }
    const geometries = arrangeLayout(
      surface.area,
      state.windows,
      layout,
      config,
      8
    );
    expect(geometries.length).toBe(id === "quarter" ? 4 : 8);
    for (const geometry of geometries) {
      expect(
        Number.isFinite(geometry.x) && Number.isFinite(geometry.y)
      ).toBeTruthy();
      expect(geometry.width > 0 && geometry.height > 0).toBeTruthy();
      expect(
        geometry.x >= surface.area.x && geometry.y >= surface.area.y
      ).toBeTruthy();
      expect(
        geometry.x + geometry.width <=
          surface.area.x + surface.area.width + 0.01
      ).toBeTruthy();
      expect(
        geometry.y + geometry.height <=
          surface.area.y + surface.area.height + 0.01
      ).toBeTruthy();
    }
  });
}
it("filters leave excluded windows untouched and sole sizing is centered", () => {
  const config = {
    ...defaultConfig,
    soleWindowHeight: 60,
    soleWindowWidth: 50,
  };
  let state = setup(1, config);
  const ignoredWindow = window("shell", { resourceClass: "plasmashell" });
  const result = reduce(
    state,
    { type: "upsert", window: ignoredWindow },
    config
  );
  ({ state } = result);
  expect(
    sameRect(
      state.windows.find((entry) => entry.id === "shell")?.geometry ??
        surface.area,
      ignoredWindow.geometry
    )
  ).toBeTruthy();
  expect(
    !result.commands.some(
      (command) => "id" in command && command.id === "shell"
    )
  ).toBeTruthy();
  expect(state.windows[0]?.geometry).toStrictEqual({
    height: 630,
    width: 960,
    x: 480,
    y: 240,
  });
});
it("float toggle restores the native float geometry and upserts preserve user mode", () => {
  let state = setup();
  state = send(state, { action: "toggleFloat", type: "action" });
  expect(state.windows[0]?.floating).toBe(true);
  expect(state.windows[0]?.geometry).toStrictEqual(window("0").geometry);
  state = send(state, {
    type: "upsert",
    window: window("0", { caption: "changed" }),
  });
  expect(state.windows[0]?.floating).toBe(true);
  state = send(state, { action: "toggleFloat", type: "action" });
  expect(state.windows[0]?.floating).toBe(false);
  expect(state.windows[0]?.geometry.width).toBe(960);
});
it("master action toggles between the selected and previous master", () => {
  let state = send(setup(3), { id: "2", type: "focus" });
  state = send(state, { action: "setMaster", type: "action" });
  expect(state.windows[0]?.id).toBe("2");
  state = send(state, { action: "setMaster", type: "action" });
  expect(state.windows[0]?.id).toBe("0");
});
it("monocle restores only the maximize and minimize states it manages", () => {
  const config = { ...defaultConfig, monocleMinimizeRest: true };
  let state = setup(2, config);
  state = send(state, { action: "layout:monocle", type: "action" }, config);
  expect(state.windows[0]?.layoutMaximized).toBe(true);
  expect(state.windows[1]?.layoutMinimized).toBe(true);
  const result = reduce(
    state,
    { action: "layout:tile", type: "action" },
    config
  );
  expect(
    result.commands.some(
      (command) => command.type === "maximize" && !command.maximized
    )
  ).toBeTruthy();
  expect(
    result.commands.some(
      (command) => command.type === "minimize" && !command.minimized
    )
  ).toBeTruthy();
});
it("per desktop layout state can be shared deliberately and remembered", () => {
  const second = { ...surface, desktop: "2", id: "display:2" };
  let state = setup();
  state = send(state, { action: "layout:spiral", type: "action" });
  state = send(state, { surfaces: [second], type: "surfaces" });
  expect(state.layouts[surfaceKey(second, defaultConfig)]?.id).toBe("tile");
  const config = { ...defaultConfig, layoutPerDesktop: false };
  state = setup(2, config);
  state = send(state, { action: "layout:spiral", type: "action" }, config);
  state = send(state, { surfaces: [second], type: "surfaces" }, config);
  expect(state.layouts[surfaceKey(second, config)]?.id).toBe("spiral");
});
it("resizing adjusts a master split and rotation survives layout switches", () => {
  let state = setup();
  const [master] = state.windows;
  expect(master).toBeTruthy();
  if (master === undefined) {
    throw new Error("Expected master to be defined");
  }
  state = send(state, {
    geometry: { ...master.geometry, width: master.geometry.width + 192 },
    id: master.id,
    type: "resize",
  });
  expect(state.layouts[surfaceKey(surface, defaultConfig)]?.ratio).toBe(0.6);
  state = send(state, { action: "rotate", type: "action" });
  state = send(state, { action: "layout:stair", type: "action" });
  state = send(state, { action: "layout:tile", type: "action" });
  expect(state.layouts[surfaceKey(surface, defaultConfig)]?.rotation).toBe(1);
});
it("named surface labels apply gap overrides and reserve dock space", () => {
  const config = {
    ...defaultConfig,
    dockWindowClassConfig: ["panel:auto,left:vw=20,vh=100"],
    gapsOverrideConfig: ["primary:l=8,e=10"],
    srfDefineCfg: ["primary=DP-1:Desktop 1:work"],
  };
  expect(getGaps(surface, config).left).toBe(8);
  let state = setup(1, config);
  state = send(
    state,
    { type: "upsert", window: window("dock", { resourceClass: "panel" }) },
    config
  );
  expect(state.windows.find((entry) => entry.id === "dock")?.docked).toBe(true);
  expect(state.windows.find((entry) => entry.id === "0")?.geometry.x).toBe(392);
});
it("capacity overflow moves to a free output and blocked overflow remains afloat", () => {
  const other = {
    ...surface,
    area: { ...surface.area, x: 1920 },
    id: "display:other",
    screen: "DP-2",
  };
  const config = { ...defaultConfig, tileLayoutCapacity: 1 };
  let state = send(
    createState(),
    { surfaces: [surface, other], type: "surfaces" },
    config
  );
  state = send(state, { type: "upsert", window: window("0") }, config);
  const result = reduce(state, { type: "upsert", window: window("1") }, config);
  expect(
    result.state.windows.find((entry) => entry.id === "1")?.surfaceId
  ).toBe(other.id);
  expect(
    result.commands.some(
      (command) =>
        command.type === "surface" &&
        command.id === "1" &&
        command.surfaceId === other.id
    )
  ).toBeTruthy();
});
it("completed shortcut sequences use custom actions and register expires", () => {
  const config = {
    ...defaultConfig,
    shortcutConf: ["FocusLeftSC,FocusRightSC:ma=ToggleFloatAll,st=500"],
  };
  let state = setup(2, config);
  state = send(
    state,
    {
      action: "focusLeft",
      shortcut: "FocusLeftSC",
      time: 1000,
      type: "action",
    },
    config
  );
  expect(state.shortcutKeys).toStrictEqual(["FocusLeftSC"]);
  state = send(
    state,
    {
      action: "focusRight",
      shortcut: "FocusRightSC",
      time: 1200,
      type: "action",
    },
    config
  );
  expect(state.windows[0]?.floating).toBe(true);
  state = send(
    state,
    { action: "alterRegister", time: 2000, type: "action" },
    config
  );
  expect(state.register).toBe(true);
  state = send(
    state,
    { action: "focusNext", time: 6000, type: "action" },
    config
  );
  expect(state.register).toBe(false);
});
it("the reducer never mutates the previous state", () => {
  const state = setup();
  const serialized = JSON.stringify(state);
  send(state, { action: "growWidth", type: "action" });
  expect(JSON.stringify(state)).toBe(serialized);
});
it("upstream rotation indexes and degree aliases retain stack order", () => {
  const indexed = { ...defaultConfig, tileLayoutInitialRotationAngle: "1" };
  const degrees = { ...defaultConfig, tileLayoutInitialRotationAngle: "90" };
  const indexState = setup(3, indexed);
  const degreeState = setup(3, degrees);
  expect(indexState.windows.map((entry) => entry.geometry)).toStrictEqual(
    degreeState.windows.map((entry) => entry.geometry)
  );
  expect(indexState.windows[0]?.geometry.y).toBe(30);
  expect(indexState.windows[1]?.geometry.x).toBe(0);
  expect(indexState.windows[2]?.geometry.x).toBe(960);
  const mirrored = setup(3, {
    ...defaultConfig,
    tileLayoutInitialRotationAngle: "2",
  });
  expect(mirrored.windows[0]?.geometry.x).toBe(960);
  expect(mirrored.windows[1]?.geometry.y).toBe(30);
});
it("Columns uses upstream North rows and West columns orientation", () => {
  const northConfig = {
    ...defaultConfig,
    columnsLayerConf: ["DP-1:work:Desktop 1:1:1"],
    screenDefaultLayout: ["DP-1:columns"],
  };
  const north = setup(2, northConfig);
  expect(north.windows[0]?.geometry.y).toBe(30);
  expect(north.windows[1]?.geometry.y).toBe(555);
  const west = setup(2, {
    ...northConfig,
    columnsLayoutInitialRotationAngle: "3",
  });
  expect(west.windows[0]?.geometry.x).toBe(0);
  expect(west.windows[1]?.geometry.x).toBe(960);
});
it("screen default layout numbers are upstream zero based indexes", () => {
  const state = setup(2, { ...defaultConfig, screenDefaultLayout: ["DP-1:1"] });
  expect(state.layouts[surfaceKey(surface, defaultConfig)]?.id).toBe("monocle");
});
it("Second new-window position follows the surface master", () => {
  const config = { ...defaultConfig, newWindowPosition: 2 };
  const state = setup(4, config);
  expect(state.windows.map((entry) => entry.id)).toStrictEqual([
    "0",
    "3",
    "2",
    "1",
  ]);
});
it("inactive desktop records retain manual mode and weights", () => {
  const inactive = { ...surface, active: false, desktop: "2", id: "inactive" };
  let state = setup();
  state = send(state, { action: "toggleFloat", type: "action" });
  state = send(state, { surfaces: [surface, inactive], type: "surfaces" });
  const result = reduce(state, {
    type: "upsert",
    window: window("0", { surfaceId: inactive.id, visible: false }),
  });
  expect(result.state.windows[0]?.floating).toBe(true);
  expect(result.state.windows[0]?.manualFloating).toBe(true);
  expect(
    !result.commands.some((command) => "id" in command && command.id === "0")
  ).toBeTruthy();
  const returned = send(result.state, {
    type: "upsert",
    window: window("0", { surfaceId: surface.id, visible: true }),
  });
  expect(returned.windows[0]?.floating).toBe(true);
});
it("configuration reload reclassifies rules while retaining manual overrides", () => {
  let state = setup();
  state = send(state, { action: "toggleFloat", type: "action" });
  state = send(state, { id: "1", type: "focus" });
  state = send(
    state,
    { type: "arrange" },
    { ...defaultConfig, floatingClass: ["kitty"] }
  );
  expect(state.windows[0]?.floating).toBe(true);
  expect(state.windows[1]?.floating).toBe(true);
  state = send(state, { type: "arrange" }, defaultConfig);
  expect(state.windows[0]?.floating).toBe(true);
  expect(state.windows[1]?.floating).toBe(false);
  state = send(
    state,
    { type: "arrange" },
    { ...defaultConfig, dockWindowClassConfig: ["kitty:auto,top:hh=20"] }
  );
  expect(state.windows[1]?.docked).toBe(true);
  expect(state.windows[0]?.docked).toBe(false);
});
it("inactive desktops can receive overflow without geometry writes", () => {
  const other = { ...surface, active: false, desktop: "2", id: "desktop:2" };
  const config = { ...defaultConfig, tileLayoutCapacity: 1 };
  let state = send(
    createState(),
    { surfaces: [surface, other], type: "surfaces" },
    config
  );
  state = send(state, { type: "upsert", window: window("0") }, config);
  const result = reduce(state, { type: "upsert", window: window("1") }, config);
  expect(
    result.state.windows.find((entry) => entry.id === "1")?.surfaceId
  ).toBe(other.id);
  expect(
    !result.commands.some(
      (command) => command.type === "geometry" && command.id === "1"
    )
  ).toBeTruthy();
});
it("dialogs, modal, non-resizable and resource-name rules match upstream eligibility", () => {
  let state = setup(1);
  state = send(state, {
    type: "upsert",
    window: window("modal", { modal: true }),
  });
  state = send(state, {
    type: "upsert",
    window: window("dialog", { dialog: true }),
  });
  state = send(state, {
    type: "upsert",
    window: window("fixed", { resizeable: false }),
  });
  for (const id of ["modal", "dialog", "fixed"]) {
    expect(state.windows.find((entry) => entry.id === id)?.floating).toBe(true);
  }
  const result = reduce(state, {
    type: "upsert",
    window: window("resource", { resourceName: "krunner" }),
  });
  expect(
    !result.commands.some(
      (command) => "id" in command && command.id === "resource"
    )
  ).toBeTruthy();
});
it("monocle directional focus cycles coincident windows", () => {
  let state = send(setup(3), { action: "layout:monocle", type: "action" });
  state = send(state, { action: "focusRight", type: "action" });
  expect(state.focusId).toBe("1");
  state = send(state, { action: "focusLeft", type: "action" });
  expect(state.focusId).toBe("0");
});
