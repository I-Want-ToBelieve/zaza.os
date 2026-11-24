import {
  type Config,
  defaultConfig,
  parseShortcutRules,
} from "@krohnkite/config";
import { expect, it } from "vitest";
import {
  arrangeDocks,
  createState,
  type EngineEvent,
  type EngineState,
  type ManagedWindow,
  reduce,
  type Surface,
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
  fields: Partial<ManagedWindow> = {}
): ManagedWindow => ({
  caption: id,
  geometry: { height: 400, width: 600, x: 50, y: 60 },
  id,
  resourceClass: "kitty",
  role: "",
  surfaceId: surface.id,
  ...fields,
});
const send = (
  state: EngineState,
  event: EngineEvent,
  config: Config
): EngineState => reduce(state, event, config).state;
function setup(config: Config = defaultConfig, count = 3): EngineState {
  let state = send(
    createState(config),
    { surfaces: [surface], type: "surfaces" },
    config
  );
  for (let index = 0; index < count; index += 1) {
    state = send(
      state,
      { type: "upsert", window: window(String(index)) },
      config
    );
  }
  return send(state, { id: "0", type: "focus" }, config);
}
const press = (
  state: EngineState,
  shortcut: string,
  time: number,
  config: Config
): EngineState =>
  send(state, { action: "focusNext", shortcut, time, type: "action" }, config);
const drag = (
  state: EngineState,
  id: string,
  x: number,
  y: number,
  config: Config,
  finished = true
) =>
  reduce(
    state,
    {
      finished,
      geometry: { height: 300, width: 400, x: x - 100, y: y - 100 },
      id,
      pointer: { x, y },
      type: "drag",
    },
    config
  );

it("sequence timeout executes the delayed first-key action and ignores stale timers", () => {
  const config = {
    ...defaultConfig,
    shortcutConf: ["FocusNextSC,FocusPrevSC:ma=ToggleFloatAll,st=100"],
  };
  const initial = setup(config);
  const pending = reduce(
    initial,
    {
      action: "focusNext",
      shortcut: "FocusNextSC",
      time: 1000,
      type: "action",
    },
    config
  );
  expect(pending.state.focusId).toBe("0");
  expect(
    pending.commands.some(
      (command) => command.type === "shortcutTimer" && command.deadline === 1100
    )
  ).toBeTruthy();
  expect(
    send(pending.state, { time: 1099, type: "shortcutTimeout" }, config)
  ).toBe(pending.state);
  const finished = send(
    pending.state,
    { time: 1100, type: "shortcutTimeout" },
    config
  );
  expect(finished.focusId).toBe("1");
  expect(finished.shortcutKeys).toStrictEqual([]);
  expect(send(finished, { time: 1200, type: "shortcutTimeout" }, config)).toBe(
    finished
  );
});
const overlapping: Config = {
  ...defaultConfig,
  shortcutConf: [
    "FocusNextSC,FocusPrevSC:ma=ToggleFloatAll,st=100",
    "FocusNextSC,FocusPrevSC,FocusRightSC:ma=SetMonocleLayout,st=300",
  ],
};
it("shorter complete sequences wait for the longer prefix and remain timeout candidates", () => {
  expect(
    parseShortcutRules(overlapping).map((rule) => rule.timeout)
  ).toStrictEqual([300, 300]);
  let state = press(setup(overlapping), "FocusNextSC", 1000, overlapping);
  state = press(state, "FocusPrevSC", 1150, overlapping);
  expect(state.shortcutDeadline).toBe(1450);
  expect(state.windows[0]?.floating).toBe(false);
  const stale = send(
    state,
    { time: 1300, type: "shortcutTimeout" },
    overlapping
  );
  expect(stale).toBe(state);
  state = send(state, { time: 1450, type: "shortcutTimeout" }, overlapping);
  expect(state.windows.every((entry) => entry.floating)).toBeTruthy();
});
it("a complete longer sequence wins and a mismatched continuation consumes both keys", () => {
  let state = press(setup(overlapping), "FocusNextSC", 1000, overlapping);
  state = press(state, "FocusPrevSC", 1150, overlapping);
  state = press(state, "FocusRightSC", 1200, overlapping);
  expect(state.layouts[surfaceKey(surface, overlapping)]?.id).toBe("monocle");
  expect(state.windows.every((entry) => !entry.floating)).toBeTruthy();
  state = press(setup(overlapping), "FocusNextSC", 1000, overlapping);
  state = press(state, "FocusRightSC", 1010, overlapping);
  expect(state.focusId).toBe("0");
  expect(state.shortcutKeys).toStrictEqual([]);
});
it("double AlterRegister selects the persistent register and ordinary actions refresh idle expiry", () => {
  const config = { ...defaultConfig, altRegisterIsPushedTwice: true };
  let state = send(
    setup(config),
    {
      action: "alterRegister",
      shortcut: "AlterRegisterSC",
      time: 1000,
      type: "action",
    },
    config
  );
  expect(state.register).toBe(false);
  state = send(
    state,
    {
      action: "alterRegister",
      shortcut: "AlterRegisterSC",
      time: 1100,
      type: "action",
    },
    config
  );
  expect(state.register).toBe(true);
  expect(state.registerMode).toBe(true);
  expect(
    send(state, { time: 10_000, type: "shortcutTimeout" }, config).register
  ).toBe(true);
  let temporary = send(
    setup(),
    { action: "alterRegister", time: 1000, type: "action" },
    defaultConfig
  );
  temporary = send(
    temporary,
    { action: "focusNext", time: 2000, type: "action" },
    defaultConfig
  );
  expect(
    send(temporary, { time: 4000, type: "shortcutTimeout" }, defaultConfig)
      .register
  ).toBe(true);
  expect(
    send(temporary, { time: 5000, type: "shortcutTimeout" }, defaultConfig)
      .register
  ).toBe(false);
});
it("alternate MoveDown swaps windows and custom sequence register actions are resolved once", () => {
  let state = send(
    setup(),
    { action: "alterRegister", time: 1000, type: "action" },
    defaultConfig
  );
  state = send(
    state,
    { action: "moveDown", shortcut: "MoveDownSC", time: 1100, type: "action" },
    defaultConfig
  );
  expect(state.windows.map((entry) => entry.id)).toStrictEqual(["1", "0", "2"]);
  const config = {
    ...defaultConfig,
    shortcutConf: [
      "FocusNextSC,FocusPrevSC:ma=SetTileLayout,ra=ToggleFloatAll",
    ],
  };
  state = send(
    setup(config),
    { action: "alterRegister", time: 1000, type: "action" },
    config
  );
  state = press(state, "FocusNextSC", 1100, config);
  state = press(state, "FocusPrevSC", 1200, config);
  expect(state.windows.every((entry) => entry.floating)).toBeTruthy();
});
it("dock pixel zones use the pointer and live previews suppress dragged geometry commits", () => {
  const initial = setup();
  const live = drag(initial, "0", 8, 600, defaultConfig, false);
  expect(
    live.state.windows.find((entry) => entry.id === "0")?.dockPosition
  ).toBe("left");
  expect(live.state.windows.find((entry) => entry.id === "0")?.docked).toBe(
    true
  );
  expect(
    live.commands.some(
      (command) => command.type === "dragPreview" && command.geometry !== null
    )
  ).toBeTruthy();
  expect(
    !live.commands.some(
      (command) => command.type === "geometry" && command.id === "0"
    )
  ).toBeTruthy();
  const finished = drag(live.state, "0", 8, 600, defaultConfig);
  expect(finished.state.drag).toBe(null);
  expect(
    finished.commands.some(
      (command) => command.type === "geometry" && command.id === "0"
    )
  ).toBeTruthy();
  expect(
    finished.commands.some(
      (command) => command.type === "dragPreview" && command.geometry === null
    )
  ).toBeTruthy();
  const beyond = drag(initial, "0", 20, 600, defaultConfig);
  expect(beyond.state.windows.find((entry) => entry.id === "0")?.docked).toBe(
    false
  );
});
it("dock drag swaps occupied slots and restores the displaced partner when leaving", () => {
  let state = setup();
  state = send(state, { action: "dockRight", type: "action" }, defaultConfig);
  const target = state.windows.find((entry) => entry.id === "0");
  expect(target).toBeTruthy();
  if (target === undefined) {
    throw new Error("Expected target to be defined");
  }
  ({ state } = drag(
    state,
    "1",
    target.geometry.x + 30,
    600,
    defaultConfig,
    false
  ));
  expect(state.windows.find((entry) => entry.id === "1")?.docked).toBe(true);
  expect(state.windows.find((entry) => entry.id === "0")?.docked).toBe(false);
  ({ state } = drag(state, "1", 1000, 600, defaultConfig, false));
  expect(state.windows.find((entry) => entry.id === "1")?.docked).toBe(false);
  expect(state.windows.find((entry) => entry.id === "0")?.docked).toBe(true);
});
it("docked-to-docked dragging exchanges their slots", () => {
  let state = setup();
  state = send(state, { action: "dockLeft", type: "action" }, defaultConfig);
  state = send(state, { id: "1", type: "focus" }, defaultConfig);
  state = send(state, { action: "dockRight", type: "action" }, defaultConfig);
  ({ state } = drag(state, "0", 1800, 600, defaultConfig, false));
  expect(state.windows.find((entry) => entry.id === "0")?.dockPosition).toBe(
    "right"
  );
  expect(state.windows.find((entry) => entry.id === "1")?.dockPosition).toBe(
    "left"
  );
  ({ state } = drag(state, "0", 1800, 600, defaultConfig));
  expect(state.windows.find((entry) => entry.id === "0")?.dockPosition).toBe(
    "right"
  );
  expect(state.windows.find((entry) => entry.id === "1")?.dockPosition).toBe(
    "left"
  );
});
it("disabled dock slots and pin priorities follow upstream arbitration", () => {
  const config = {
    ...defaultConfig,
    dockOrderBottom: 0,
    dockOrderRight: 0,
    dockOrderTop: 0,
    dockWindowClassConfig: ["kitty:auto,left:", "pin:auto,pin,left:"],
  };
  let state = setup(config, 1);
  state = send(
    state,
    { type: "upsert", window: window("pin", { resourceClass: "pin" }) },
    config
  );
  expect(state.windows.find((entry) => entry.id === "pin")?.docked).toBe(true);
  expect(state.windows.find((entry) => entry.id === "0")?.docked).toBe(false);
  ({ state } = drag(state, "0", 1000, 30, config));
  expect(state.windows.find((entry) => entry.id === "0")?.docked).toBe(false);
});
it("named dock alignment trims its frame inside the reserved strip", () => {
  const config = {
    ...defaultConfig,
    dockWindowClassConfig: [
      "kitty:auto,left:vw=20,vh=50,va=bottom,ve=middle,vgv=10,vgh=8",
    ],
  };
  const docking = arrangeDocks(
    surface,
    [window("dock", { docked: true, dockPosition: "left" })],
    config
  );
  expect(docking.area).toStrictEqual({
    height: 1050,
    width: 1536,
    x: 384,
    y: 30,
  });
  expect(docking.geometries.get("dock")).toStrictEqual({
    height: 525,
    width: 368,
    x: 8,
    y: 545,
  });
});
it("dock grow and resize retain their percentage dimensions after arrangements", () => {
  let state = send(
    setup(),
    { action: "dockLeft", type: "action" },
    defaultConfig
  );
  state = send(state, { action: "growWidth", type: "action" }, defaultConfig);
  expect(state.windows.find((entry) => entry.id === "0")?.geometry.width).toBe(
    307.2
  );
  const geometry = state.windows.find((entry) => entry.id === "0")?.geometry;
  expect(geometry).toBeTruthy();
  if (geometry === undefined) {
    throw new Error("Expected geometry to be defined");
  }
  state = send(
    state,
    {
      geometry: { ...geometry, width: geometry.width + 19.2 },
      id: "0",
      type: "resize",
    },
    defaultConfig
  );
  expect(
    state.windows.find((entry) => entry.id === "0")?.dockOverrides?.vw
  ).toBe("17");
  state = send(state, { type: "arrange" }, defaultConfig);
  expect(state.windows.find((entry) => entry.id === "0")?.geometry.width).toBe(
    326.4
  );
});
const columnsConfig: Config = {
  ...defaultConfig,
  columnsLayerConf: ["DP-1:work:Desktop 1:1:1"],
  screenDefaultLayout: ["DP-1:columns"],
};
it("Columns drop changes membership and inserts before or after the pointed window", () => {
  let state = setup(columnsConfig);
  ({ state } = drag(state, "0", 1500, 750, columnsConfig));
  expect(state.windows.map((entry) => entry.id)).toStrictEqual(["1", "0", "2"]);
  const key = surfaceKey(surface, columnsConfig);
  expect(state.layouts[key]?.columns["0"]).toBe(
    state.layouts[key]?.columns["1"]
  );
  ({ state } = drag(state, "2", 100, 750, columnsConfig));
  expect(state.windows.map((entry) => entry.id)).toStrictEqual(["2", "1", "0"]);
});
it("Columns edge drops create rows and the configured limit reuses the edge row", () => {
  const initial = setup(columnsConfig);
  const inserted = drag(initial, "0", 1000, 60, columnsConfig).state;
  const key = surfaceKey(surface, columnsConfig);
  expect(inserted.layouts[key]?.columns["0"]).toBe(0);
  expect(inserted.layouts[key]?.columns["2"]).toBe(1);
  expect(inserted.layouts[key]?.columns["1"]).toBe(2);
  const limitedConfig = { ...columnsConfig, columnsLimitColumns: true };
  const limited = drag(
    setup(limitedConfig),
    "1",
    1000,
    60,
    limitedConfig
  ).state;
  expect(limited.layouts[key]?.columns["1"]).toBe(0);
  expect(limited.layouts[key]?.columns["2"]).toBe(0);
});
it("nonlive tile resizing waits for its final event", () => {
  const config = { ...defaultConfig, adjustLayoutLive: false };
  const initial = setup(config);
  const geometry = initial.windows[0]?.geometry;
  expect(geometry).toBeTruthy();
  if (geometry === undefined) {
    throw new Error("Expected geometry to be defined");
  }
  const resized = { ...geometry, width: geometry.width + 200 };
  expect(
    send(
      initial,
      { finished: false, geometry: resized, id: "0", type: "resize" },
      config
    )
  ).toBe(initial);
  const finished = send(
    initial,
    { finished: true, geometry: resized, id: "0", type: "resize" },
    config
  );
  expect(
    (finished.windows[0]?.geometry.width ?? 0) > geometry.width
  ).toBeTruthy();
});
