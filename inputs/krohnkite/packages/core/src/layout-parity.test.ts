import { defaultConfig, layoutIds } from "@krohnkite/config";
import { expect, it } from "vitest";
import fixtures from "../fixtures/layouts.json" with { type: "json" };
import {
  arrangeLayout,
  createState,
  type ManagedWindow,
  reduce,
  surfaceKey,
} from "./index.js";

// The fixture importer evaluates unmodified pinned upstream source. A one-pixel
// tolerance allows the rewrite's continuous integer endpoints on odd dimensions.
for (const fixture of fixtures) {
  it(`upstream parity ${fixture.id}/${fixture.count}/gap${fixture.gap}/rotation${fixture.rotation}`, () => {
    const id = layoutIds.find((entry) => entry === fixture.id);
    expect(id).toBeTruthy();
    if (id === undefined) {
      throw new Error("Expected id to be defined");
    }
    const config = {
      ...defaultConfig,
      columnsLayoutInitialRotationAngle: String(fixture.rotation),
      screenDefaultLayout: [`DP-1:${id}`],
      srfExceededToScreen: false,
      srfExceededToVDesktop: false,
      tileLayoutInitialRotationAngle: String(fixture.rotation),
    };
    const surface = {
      activity: "work",
      area: fixture.area,
      desktop: "1",
      desktopName: "Desktop 1",
      id: "upstream",
      screen: "DP-1",
    };
    let { state } = reduce(
      createState(),
      { surfaces: [surface], type: "surfaces" },
      config
    );
    for (let index = 0; index < fixture.count; index += 1) {
      const window: ManagedWindow = {
        caption: "Fixture",
        geometry: { height: 400, width: 600, x: 50, y: 60 },
        id: String(index),
        resourceClass: "kitty",
        role: "",
        stackingOrder: index,
        surfaceId: surface.id,
      };
      ({ state } = reduce(state, { type: "upsert", window }, config));
    }
    const layout = state.layouts[surfaceKey(surface, config)];
    expect(layout).toBeTruthy();
    if (layout === undefined) {
      throw new Error("Expected layout to be defined");
    }
    const actual = arrangeLayout(
      fixture.area,
      state.windows,
      layout,
      config,
      fixture.gap
    );
    expect(actual.length).toBe(fixture.geometries.length);
    fixture.geometries.forEach((expected, index) => {
      const geometry = actual[index];
      expect(geometry).toBeTruthy();
      if (geometry === undefined) {
        throw new Error("Expected geometry to be defined");
      }
      for (const key of ["x", "y", "width", "height"] as const) {
        expect(
          Math.abs(geometry[key] - expected[key]) <= 1,
          `${id} window ${index} ${key}: expected ${expected[key]}, actual ${geometry[key]}`
        ).toBeTruthy();
      }
    });
  });
}
