import { expect, it } from "vitest";
import {
  defaultConfig,
  layoutIds,
  parseShortcutRules,
  rawDefaults,
  readConfig,
  shortcutActions,
} from "./index.js";

it("the configuration baseline preserves every upstream key", () => {
  expect(Object.keys(rawDefaults).length).toBe(145);
  expect(defaultConfig.layoutOrder).toStrictEqual(layoutIds);
  expect(defaultConfig.monocleMaximize).toBe(true);
  expect(defaultConfig.ignoreClass.includes("plasmashell")).toBeTruthy();
});
it("KConfig inputs are decoded and bounded at the boundary", () => {
  const inputs: Readonly<Record<string, unknown>> = {
    ignoreClass: "foo, bar, ,baz",
    layoutPerDesktop: "not-a-bool",
    monocleMaximize: "false",
    monocleMinimizeRest: true,
    preventMinimize: true,
    screenGapBetween: "oops",
    screenGapLeft: -20,
    soleWindowHeight: "30",
    soleWindowWidth: 500,
  };
  const config = readConfig((key, value) => inputs[key] ?? value);
  expect(config.screenGapLeft).toBe(0);
  expect(config.soleWindowWidth).toBe(100);
  expect(config.soleWindowHeight).toBe(30);
  expect(config.monocleMaximize).toBe(false);
  expect(config.layoutPerDesktop).toBe(true);
  expect(config.screenGapBetween).toBe(0);
  expect(config.preventMinimize).toBe(false);
  expect(config.ignoreClass).toStrictEqual(["foo", "bar", "baz"]);
});
it("disabled layouts retain deterministic order and an empty order falls back to tile", () => {
  const config = readConfig((key, value) => {
    if (!key.endsWith("LayoutOrder")) {
      return value;
    }
    if (key === "monocleLayoutOrder") {
      return 1;
    }
    if (key === "tileLayoutOrder") {
      return 2;
    }
    return 0;
  });
  expect(config.layoutOrder).toStrictEqual(["monocle", "tile"]);
  const empty = readConfig((key, value) =>
    key.endsWith("LayoutOrder") ? 0 : value
  );
  expect(empty.layoutOrder).toStrictEqual(["tile"]);
});
it("multiline configuration preserves commas inside override rules", () => {
  const config = readConfig((key, value) =>
    key === "gapsOverrideConfig"
      ? "# comment\nDP-1:left=8,right=9\nDP-2:between=6"
      : value
  );
  expect(config.gapsOverrideConfig).toStrictEqual([
    "DP-1:left=8,right=9",
    "DP-2:between=6",
  ]);
});
it("native string lists preserve rules and malformed arrays use the baseline", () => {
  const inputs: Readonly<Record<string, unknown>> = {
    floatingClass: ["kitty", 17],
    gapsOverrideConfig: [
      "# comment",
      " DP-1:left=8,right=9 ",
      "",
      "DP-2:between=6",
    ],
    ignoreClass: [" kitty ", "org.kde.systemsettings", ""],
    ignoreTitle: [null],
    layoutPerDesktop: [false],
    screenGapLeft: [24],
    shortcutConf: ["FocusLeftSC,FocusRightSC:ma=ToggleFloatAll,st=450"],
  };
  const config = readConfig((key, fallback) => inputs[key] ?? fallback);
  expect(config.ignoreClass).toStrictEqual(["kitty", "org.kde.systemsettings"]);
  expect(config.gapsOverrideConfig).toStrictEqual([
    "DP-1:left=8,right=9",
    "DP-2:between=6",
  ]);
  expect(config.shortcutConf).toStrictEqual([
    "FocusLeftSC,FocusRightSC:ma=ToggleFloatAll,st=450",
  ]);
  expect(config.floatingClass).toStrictEqual(defaultConfig.floatingClass);
  expect(config.ignoreTitle).toStrictEqual(defaultConfig.ignoreTitle);
  expect(config.layoutPerDesktop).toBe(defaultConfig.layoutPerDesktop);
  expect(config.screenGapLeft).toBe(defaultConfig.screenGapLeft);
});
it("native KConfig decoded strings preserve file rules and reject nonfinite values", () => {
  const entries: Readonly<Record<string, unknown>> = {
    floatConfig:
      "# comment\r\norg.kde.systemsettings:width=60,height=70\r\n\r\npavucontrol:width=40,height=60",
    floatingClass: "org.kde.systemsettings, pavucontrol",
    layoutPerActivity: "false",
    notificationDuration: "Infinity",
    screenGapLeft: "12",
    screenGapRight: "",
    screenGapTop: Number.NaN,
    shortcutConf:
      "FocusNextSC:ma=FocusNext,ra=SetMonocleLayout\nFocusLeftSC,FocusRightSC:ma=ToggleFloatAll,st=450",
  };
  const config = readConfig((key, fallback) => entries[key] ?? fallback);
  expect(config.floatingClass).toStrictEqual([
    "org.kde.systemsettings",
    "pavucontrol",
  ]);
  expect(config.floatConfig).toStrictEqual([
    "org.kde.systemsettings:width=60,height=70",
    "pavucontrol:width=40,height=60",
  ]);
  expect(config.layoutPerActivity).toBe(false);
  expect(config.screenGapLeft).toBe(12);
  expect(config.screenGapRight).toBe(rawDefaults.screenGapRight);
  expect(config.screenGapTop).toBe(rawDefaults.screenGapTop);
  expect(config.notificationDuration).toBe(rawDefaults.notificationDuration);
  expect(parseShortcutRules(config)).toStrictEqual([
    {
      action: "focusNext",
      registerAction: "layout:monocle",
      shortcuts: ["FocusNextSC"],
      timeout: 400,
    },
    {
      action: "floatAll",
      registerAction: null,
      shortcuts: ["FocusLeftSC", "FocusRightSC"],
      timeout: 450,
    },
  ]);
});
it("shortcut names cover all original handlers and parse register sequences", () => {
  expect(Object.keys(shortcutActions).length).toBe(39);
  const config = {
    ...defaultConfig,
    shortcutConf: [
      "FocusNextSC:ma=SetMonocleLayout,ra=SetTileLayout",
      "FocusLeftSC,FocusRightSC:ma=ToggleFloatAll,st=450",
      "TypoSC:ma=Increase",
      "FocusDownSC:ma=Unknown",
    ],
  };
  expect(parseShortcutRules(config)).toStrictEqual([
    {
      action: "layout:monocle",
      registerAction: "layout:tile",
      shortcuts: ["FocusNextSC"],
      timeout: 400,
    },
    {
      action: "floatAll",
      registerAction: null,
      shortcuts: ["FocusLeftSC", "FocusRightSC"],
      timeout: 450,
    },
  ]);
});
