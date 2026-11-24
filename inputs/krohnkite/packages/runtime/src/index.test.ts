import { assert, expect, it } from "@effect/vitest";
import { defaultConfig } from "@krohnkite/config";
import type { Command, EngineEvent, Rect } from "@krohnkite/core";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Scheduler from "effect/Scheduler";
import {
  Compositor,
  CompositorError,
  createEngineRuntime,
  formatCause,
  type HostService,
  makeEngine,
} from "./index.ts";

const area: Rect = { height: 800, width: 1000, x: 0, y: 0 };
const compositorErrorPattern = /CompositorError/;
const added: EngineEvent = {
  type: "upsert",
  window: {
    caption: "Terminal",
    geometry: { height: 300, width: 400, x: 40, y: 50 },
    id: "one",
    resourceClass: "kitty",
    role: "",
    surfaceId: "main",
  },
};

it("Qt runtime operations and scoped cleanup never request a scheduler yield", () => {
  let checks = 0;
  let listeners = 0;
  let commands = 0;
  const reports: string[] = [];
  const scheduler: Scheduler.Scheduler = {
    executionMode: "sync",
    makeDispatcher: () => {
      throw new Error("Qt synchronous work must not allocate a dispatcher");
    },
    shouldYield: (fiber) => {
      checks += 1;
      return fiber.currentOpCount >= fiber.cache.maxOpsBeforeYield;
    },
  };
  const native = <A, E, R>(effect: Effect.Effect<A, E, R>) =>
    effect.pipe(
      Effect.provideService(Scheduler.Scheduler, scheduler),
      Effect.provideService(Scheduler.MaxOpsBeforeYield, 16)
    );
  const runtime = createEngineRuntime(defaultConfig, {
    apply: () =>
      native(
        Effect.gen(function* () {
          for (let index = 0; index < 128; index += 1) {
            yield* Effect.sync(() => {
              commands += 1;
            });
          }
        })
      ),
    observe: (send) =>
      native(
        Effect.gen(function* () {
          for (let index = 0; index < 256; index += 1) {
            yield* Effect.acquireRelease(
              Effect.sync(() => {
                listeners += 1;
              }),
              () =>
                Effect.sync(() => {
                  listeners -= 1;
                })
            );
          }
          send({
            surfaces: [
              {
                activity: "",
                area,
                desktop: "desktop",
                id: "main",
                screen: "screen",
              },
            ],
            type: "surfaces",
          });
          send(added);
        })
      ),
    report: (message) => reports.push(message),
  });
  assert.equal(runtime.start(), true);
  assert.equal(listeners, 256);
  assert.equal(runtime.configure({ ...defaultConfig, screenGapLeft: 8 }), true);
  runtime.send({ id: "one", type: "focus" });
  assert.equal(runtime.snapshot()?.focusId, "one");
  assert.ok(commands > 0);
  runtime.dispose();
  assert.equal(listeners, 0);
  assert.equal(checks, 0);
  assert.deepEqual(reports, []);
});

it("an asynchronous observer still fails boot and releases acquired Qt resources", () => {
  let listeners = 0;
  const reports: string[] = [];
  const runtime = createEngineRuntime(defaultConfig, {
    apply: () => Effect.void,
    observe: () =>
      Effect.gen(function* () {
        yield* Effect.acquireRelease(
          Effect.sync(() => {
            listeners += 1;
          }),
          () =>
            Effect.sync(() => {
              listeners -= 1;
            })
        );
        return yield* Effect.never;
      }),
    report: (message) => reports.push(message),
  });
  assert.equal(runtime.start(), false);
  assert.equal(runtime.isRunning(), false);
  assert.equal(listeners, 0);
  assert.ok(reports.some((message) => message.includes("AsyncFiberError")));
  runtime.dispose();
});

it("Effect scope owns listener acquisition and disposes exactly once", () => {
  let listeners = 0;
  const commands: Command[] = [];
  const reports: string[] = [];
  const host: HostService = {
    apply: (command) =>
      Effect.sync(() => {
        commands.push(command);
      }),
    observe: (send) =>
      Effect.gen(function* () {
        yield* Effect.acquireRelease(
          Effect.sync(() => {
            listeners += 1;
          }),
          () =>
            Effect.sync(() => {
              listeners -= 1;
            })
        );
        send({
          surfaces: [
            {
              activity: "",
              area,
              desktop: "desktop",
              id: "main",
              screen: "screen",
            },
          ],
          type: "surfaces",
        });
        send(added);
      }),
    report: (message) => reports.push(message),
  };
  const runtime = createEngineRuntime(defaultConfig, host);
  assert.equal(runtime.start(), true);
  assert.equal(runtime.start(), true);
  assert.equal(listeners, 1);
  assert.equal(runtime.snapshot()?.windows.length, 1);
  assert.ok(commands.some((command) => command.type === "geometry"));
  runtime.dispose();
  runtime.dispose();
  assert.equal(listeners, 0);
  assert.equal(runtime.start(), false);
  assert.equal(runtime.snapshot(), null);
  assert.deepEqual(reports, []);
});

it("partial observer failure closes already acquired resources", () => {
  let listeners = 0;
  const reports: string[] = [];
  const runtime = createEngineRuntime(defaultConfig, {
    apply: () => Effect.void,
    observe: () =>
      Effect.gen(function* () {
        yield* Effect.acquireRelease(
          Effect.sync(() => {
            listeners += 1;
          }),
          () =>
            Effect.sync(() => {
              listeners -= 1;
            })
        );
        return yield* new CompositorError({
          cause: "deleted",
          operation: "connect",
          target: "window",
        });
      }),
    report: (message) => reports.push(message),
  });
  assert.equal(runtime.start(), false);
  assert.equal(listeners, 0);
  assert.equal(runtime.isRunning(), false);
  assert.match(reports.join("\n"), compositorErrorPattern);
});

it("geometry callbacks enqueue events instead of recursively applying commands", () => {
  let depth = 0;
  let maxDepth = 0;
  let callback: ((event: EngineEvent) => void) | undefined;
  let injected = false;
  const runtime = createEngineRuntime(defaultConfig, {
    apply: (command) =>
      Effect.sync(() => {
        depth += 1;
        maxDepth = Math.max(depth, maxDepth);
        if (command.type === "geometry" && !injected) {
          injected = true;
          callback?.({ id: "one", type: "focus" });
        }
        depth -= 1;
      }),
    observe: (send) =>
      Effect.sync(() => {
        callback = send;
        send({
          surfaces: [
            {
              activity: "",
              area,
              desktop: "desktop",
              id: "main",
              screen: "screen",
            },
          ],
          type: "surfaces",
        });
        send(added);
      }),
    report: (message) => assert.fail(message),
  });
  assert.equal(runtime.start(), true);
  assert.equal(maxDepth, 1);
  assert.equal(runtime.snapshot()?.focusId, "one");
  runtime.dispose();
});

it("compositor command failures stay visible and do not kill later events", () => {
  const reports: string[] = [];
  let fail = true;
  const runtime = createEngineRuntime(defaultConfig, {
    apply: (command) =>
      command.type === "geometry" && fail
        ? Effect.fail(
            new CompositorError({
              cause: "denied",
              operation: "geometry",
              target: "one",
            })
          )
        : Effect.void,
    observe: (send) =>
      Effect.sync(() => {
        send({
          surfaces: [
            {
              activity: "",
              area,
              desktop: "desktop",
              id: "main",
              screen: "screen",
            },
          ],
          type: "surfaces",
        });
        send(added);
      }),
    report: (message) => reports.push(message),
  });
  assert.equal(runtime.start(), true);
  assert.match(reports.join("\n"), compositorErrorPattern);
  fail = false;
  runtime.send({ id: "one", type: "focus" });
  assert.equal(runtime.snapshot()?.focusId, "one");
  runtime.dispose();
});

it.effect(
  "Qt stacks without an error header still report the actual failure",
  () =>
    Effect.gen(function* () {
      const defect = new TypeError("invalid Qt object");
      defect.stack = "changed@file:///contents/code/krohnkite.js:231";
      const exit = yield* Effect.exit(Effect.die(defect));
      if (!Exit.isFailure(exit)) {
        return assert.fail("Expected the Qt defect to be captured in an Exit");
      }
      const message = formatCause(exit.cause);
      assert.ok(message.includes("TypeError: invalid Qt object"));
      assert.ok(
        message.includes("changed@file:///contents/code/krohnkite.js:231")
      );
    })
);

it.effect(
  "engine commits state before compositor effects and retains typed failures",
  () =>
    Effect.gen(function* () {
      const failure = new CompositorError({
        cause: "read-only geometry",
        operation: "geometry",
        target: "one",
      });
      const commands: Command[] = [];
      let rejectGeometry = true;
      const host: HostService = {
        apply: (command) =>
          Effect.gen(function* () {
            commands.push(command);
            if (command.type === "geometry" && rejectGeometry) {
              return yield* failure;
            }
          }),
        observe: () => Effect.void,
        report: (message) => assert.fail(message),
      };
      const engine = yield* makeEngine(defaultConfig).pipe(
        Effect.provideService(Compositor, host)
      );
      yield* engine.dispatch({
        surfaces: [
          {
            activity: "",
            area,
            desktop: "desktop",
            id: "main",
            screen: "screen",
          },
        ],
        type: "surfaces",
      });
      const failed = yield* Effect.exit(engine.dispatch(added));
      expect(Exit.isFailure(failed)).toBe(true);
      if (Exit.isFailure(failed)) {
        expect(failed.cause.reasons).toMatchObject([
          { _tag: "Fail", error: failure },
        ]);
      }
      const state = yield* engine.snapshot;
      expect(state.windows.map((window) => window.id)).toEqual(["one"]);
      rejectGeometry = false;
      yield* engine.configure({ ...defaultConfig, screenGapLeft: 16 });
      expect(
        commands.filter((command) => command.type === "geometry")
      ).toHaveLength(2);
      expect(
        (yield* engine.snapshot).windows.map((window) => window.id)
      ).toEqual(["one"]);
    })
);
