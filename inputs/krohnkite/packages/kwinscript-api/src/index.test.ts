import { assert, it } from "@effect/vitest";
import * as Cause from "effect/Cause";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Scheduler from "effect/Scheduler";
import * as Scope from "effect/Scope";
import {
  type KWinApi,
  KWinApiError,
  KWinScriptApi,
  makeKWinScriptApi,
  type QtSignal,
  runKWinSync,
  runKWinSyncExit,
} from "./index.ts";

it("native synchronous runners exceed a low operation budget without scheduling", () => {
  let checks = 0;
  let scheduled = 0;
  const scheduler: Scheduler.Scheduler = {
    executionMode: "sync",
    makeDispatcher: () => {
      const dispatcher = new Scheduler.MixedScheduler("sync").makeDispatcher();
      return {
        flush: () => dispatcher.flush(),
        scheduleTask: (task, priority) => {
          scheduled += 1;
          dispatcher.scheduleTask(task, priority);
        },
      };
    },
    shouldYield: (fiber) => {
      checks += 1;
      return fiber.currentOpCount >= fiber.cache.maxOpsBeforeYield;
    },
  };
  const program = Effect.gen(function* () {
    let completed = 0;
    for (let index = 0; index < 10_000; index += 1) {
      yield* Effect.sync(() => {
        completed += 1;
      });
    }
    return completed;
  }).pipe(
    Effect.provideService(Scheduler.Scheduler, scheduler),
    Effect.provideService(Scheduler.MaxOpsBeforeYield, 64)
  );
  assert.deepEqual(Effect.runSyncExit(program), Exit.succeed(10_000));
  assert.ok(checks > 0 && scheduled > 0);
  checks = 0;
  scheduled = 0;
  assert.deepEqual(runKWinSyncExit(program), Exit.succeed(10_000));
  assert.equal(runKWinSync(program), 10_000);
  assert.equal(checks, 0);
  assert.equal(scheduled, 0);
});

it("native synchronous runners still reject truly asynchronous effects", () => {
  const exit = runKWinSyncExit(Effect.never);
  assert.ok(Exit.isFailure(exit));
  assert.ok(
    exit.cause.reasons.some(
      (reason) =>
        reason._tag === "Die" && Cause.isAsyncFiberError(reason.defect)
    )
  );
});

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

const makeApi = (extensions: Partial<KWinApi> = {}): KWinApi => {
  const output = { name: "test-output" };
  const desktop = { id: "test-desktop" };
  return {
    kwin: { PlacementArea: 0 },
    log: () => undefined,
    readConfig: (_key, fallback) => fallback,
    shortcuts: [],
    workspace: {
      activeScreen: output,
      activeWindow: null,
      clientArea: () => ({ height: 800, width: 1200, x: 0, y: 0 }),
      currentActivity: "test-activity",
      currentDesktop: desktop,
      screens: [output],
      stackingOrder: [],
      windowActivated: new Signal(),
      windowAdded: new Signal(),
      windowRemoved: new Signal(),
    },
    ...extensions,
  };
};

it.effect(
  "the independent KWin Layer supplies its concrete platform service",
  () =>
    Effect.gen(function* () {
      const raw = makeApi();
      const platform = yield* Effect.service(KWinScriptApi).pipe(
        Effect.provide(KWinScriptApi.layer(raw))
      );
      assert.equal(platform.raw, raw);
      assert.equal(
        yield* platform.call("readConfig", () => raw.readConfig("gap", 8)),
        8
      );
    })
);

it.effect(
  "platform exceptions retain the typed operation, target and original cause",
  () =>
    Effect.gen(function* () {
      const original = new TypeError("QObject was deleted");
      const platform = makeKWinScriptApi(makeApi());
      const error = yield* platform
        .call(
          "geometry",
          () => {
            throw original;
          },
          "window-1"
        )
        .pipe(Effect.flip);
      assert.ok(error instanceof KWinApiError);
      assert.equal(error.operation, "geometry");
      assert.equal(error.target, "window-1");
      assert.equal(error.cause, original);
    })
);

it.effect(
  "scope closure disconnects a signal exactly once and prevents later delivery",
  () =>
    Effect.gen(function* () {
      const platform = makeKWinScriptApi(makeApi());
      const signal = new Signal<[number]>();
      const values: number[] = [];
      const parent = yield* Effect.scope;
      const scope = yield* Scope.fork(parent);
      yield* Scope.provide(
        platform.connect(signal, (value) => values.push(value)),
        scope
      );
      signal.emit(7);
      assert.deepEqual(values, [7]);
      yield* Scope.close(scope, Exit.void);
      yield* Scope.close(scope, Exit.void);
      assert.equal(signal.callbacks.size, 0);
      signal.emit(9);
      assert.deepEqual(values, [7]);
    })
);

it.effect(
  "a later failed subscription still releases earlier acquired signals",
  () =>
    Effect.gen(function* () {
      const platform = makeKWinScriptApi(makeApi());
      const acquired = new Signal();
      const broken: QtSignal = {
        connect: () => {
          throw new Error("gone");
        },
        disconnect: () => undefined,
      };
      const error = yield* Effect.scoped(
        Effect.gen(function* () {
          yield* platform.connect(acquired, () => undefined, "first");
          yield* platform.connect(broken, () => undefined, "second");
        })
      ).pipe(Effect.flip);
      assert.equal(error.operation, "connect");
      assert.equal(error.target, "second");
      assert.equal(acquired.callbacks.size, 0);
    })
);

it.effect(
  "a disconnect failure remains visible while other finalizers finish",
  () =>
    Effect.gen(function* () {
      const errors: KWinApiError[] = [];
      const platform = makeKWinScriptApi(makeApi(), {
        onError: (error) => errors.push(error),
      });
      const valid = new Signal();
      const broken: QtSignal = {
        connect: () => undefined,
        disconnect: () => {
          throw new TypeError("owner deleted");
        },
      };
      yield* Effect.scoped(
        Effect.gen(function* () {
          yield* platform.connect(valid, () => undefined, "valid");
          yield* platform.connect(broken, () => undefined, "broken");
        })
      );
      assert.equal(valid.callbacks.size, 0);
      assert.equal(errors.length, 1);
      assert.equal(errors[0]?.operation, "disconnect");
      assert.equal(errors[0]?.target, "broken");
    })
);

it.effect(
  "synchronous callback completion releases its cancellation once",
  () =>
    Effect.gen(function* () {
      const platform = makeKWinScriptApi(makeApi());
      let canceled = 0;
      const values: number[] = [];
      yield* Effect.scoped(
        platform.oneShot<number>(
          "immediate",
          (deliver) => {
            deliver(21);
            deliver(22);
            return () => {
              canceled += 1;
            };
          },
          (value) => values.push(value)
        )
      );
      assert.deepEqual(values, [21]);
      assert.equal(canceled, 1);
    })
);

it.effect(
  "native timer completion and parent closure cancel without browser timers",
  () =>
    Effect.gen(function* () {
      const pending: {
        callback: () => void;
        delay: number;
        canceled: boolean;
      }[] = [];
      const platform = makeKWinScriptApi(
        makeApi({
          scheduleTimer: (delay, callback) => {
            const timer = { callback, canceled: false, delay };
            pending.push(timer);
            return () => {
              timer.canceled = true;
            };
          },
        })
      );
      let fired = 0;
      const scope = yield* Scope.fork(yield* Effect.scope);
      yield* Scope.provide(
        platform.scheduleTimer(40, () => {
          fired += 1;
        }),
        scope
      );
      const [completed] = pending;
      assert.ok(completed);
      assert.equal(completed.delay, 40);
      completed.callback();
      completed.callback();
      assert.equal(fired, 1);
      assert.equal(completed.canceled, true);
      yield* Scope.provide(
        platform.scheduleTimer(80, () => {
          fired += 1;
        }),
        scope
      );
      const [, abandoned] = pending;
      assert.ok(abandoned);
      yield* Scope.close(scope, Exit.void);
      assert.equal(abandoned.canceled, true);
      abandoned.callback();
      assert.equal(fired, 1);
    })
);

it.effect(
  "virtual keyboard callbacks cannot run after their owner scope is closed",
  () =>
    Effect.gen(function* () {
      const pending: {
        callback: (visible: boolean) => void;
        canceled: boolean;
      }[] = [];
      const platform = makeKWinScriptApi(
        makeApi({
          queryVirtualKeyboard: (callback) => {
            const query = { callback, canceled: false };
            pending.push(query);
            return () => {
              query.canceled = true;
            };
          },
        })
      );
      const values: boolean[] = [];
      yield* Effect.scoped(
        platform.queryVirtualKeyboard(
          (visible) => values.push(visible),
          "window-1"
        )
      );
      const [abandoned] = pending;
      assert.ok(abandoned);
      assert.equal(abandoned.canceled, true);
      abandoned.callback(true);
      assert.deepEqual(values, []);
    })
);

it.effect(
  "callback exceptions are reported and still release their native resource",
  () =>
    Effect.gen(function* () {
      const errors: KWinApiError[] = [];
      const platform = makeKWinScriptApi(makeApi(), {
        onError: (error) => errors.push(error),
      });
      let canceled = 0;
      yield* platform.oneShot(
        "immediate",
        (deliver) => {
          deliver(undefined);
          return () => {
            canceled += 1;
          };
        },
        () => {
          throw new Error("callback failed");
        },
        "target"
      );
      assert.equal(canceled, 1);
      assert.equal(errors.length, 1);
      assert.equal(errors[0]?.operation, "immediate:callback");
      assert.equal(errors[0]?.target, "target");
    })
);

it.effect(
  "missing optional native bridges produce explicit typed failures",
  () =>
    Effect.gen(function* () {
      const platform = makeKWinScriptApi(makeApi());
      const timer = yield* platform
        .scheduleTimer(1, () => undefined)
        .pipe(Effect.flip);
      const keyboard = yield* platform
        .queryVirtualKeyboard(() => undefined)
        .pipe(Effect.flip);
      assert.equal(timer.operation, "timer");
      assert.equal(keyboard.operation, "virtualKeyboard");
    })
);

it.effect(
  "late signal delivery is suppressed even when native disconnect fails",
  () =>
    Effect.gen(function* () {
      const errors: KWinApiError[] = [];
      const retained = new Set<() => void>();
      const signal: QtSignal = {
        connect: (callback) => {
          retained.add(callback);
        },
        disconnect: () => {
          throw new Error("QObject already deleted");
        },
      };
      const platform = makeKWinScriptApi(makeApi(), {
        onError: (error) => errors.push(error),
      });
      let deliveries = 0;
      const scope = yield* Scope.fork(yield* Effect.scope);
      yield* Scope.provide(
        platform.connect(
          signal,
          () => {
            deliveries += 1;
          },
          "window-1"
        ),
        scope
      );
      for (const callback of retained) {
        callback();
      }
      assert.equal(deliveries, 1);
      yield* Scope.close(scope, Exit.void);
      yield* Scope.close(scope, Exit.void);
      for (const callback of retained) {
        callback();
      }
      assert.equal(deliveries, 1);
      assert.equal(errors.length, 1);
      assert.equal(errors[0]?.operation, "disconnect");
    })
);

it.effect(
  "registration against an already closed scope cannot deliver or allocate",
  () =>
    Effect.gen(function* () {
      const platform = makeKWinScriptApi(makeApi());
      const scope = yield* Scope.fork(yield* Effect.scope);
      yield* Scope.close(scope, Exit.void);
      let registrations = 0;
      let deliveries = 0;
      yield* Scope.provide(
        platform.oneShot(
          "closed",
          (deliver) => {
            registrations += 1;
            deliver(undefined);
            return () => undefined;
          },
          () => {
            deliveries += 1;
          }
        ),
        scope
      );
      const signal: QtSignal = {
        connect: () => {
          registrations += 1;
        },
        disconnect: () => undefined,
      };
      yield* Scope.provide(
        platform.connect(signal, () => {
          deliveries += 1;
        }),
        scope
      );
      assert.equal(registrations, 0);
      assert.equal(deliveries, 0);
    })
);

it.effect(
  "an owner closed during registration suppresses delivery and cancels once",
  () =>
    Effect.gen(function* () {
      const platform = makeKWinScriptApi(makeApi());
      const scope = yield* Scope.fork(yield* Effect.scope);
      const runQtCallback = Effect.runSyncWith(yield* Effect.context<never>());
      let deliveries = 0;
      let canceled = 0;
      yield* Scope.provide(
        platform.oneShot(
          "reentrant",
          (deliver) => {
            // Simulates QML disposing the owner before registration returns its canceler.
            runQtCallback(Scope.close(scope, Exit.void));
            deliver(undefined);
            return () => {
              canceled += 1;
            };
          },
          () => {
            deliveries += 1;
          }
        ),
        scope
      );
      assert.equal(deliveries, 0);
      assert.equal(canceled, 1);
    })
);

it.effect(
  "a throwing callback reporter cannot retain the native one-shot resource",
  () =>
    Effect.gen(function* () {
      const logs: string[] = [];
      const platform = makeKWinScriptApi(
        makeApi({ log: (message) => logs.push(message) }),
        {
          onError: () => {
            throw new Error("reporter failed");
          },
        }
      );
      let canceled = 0;
      yield* platform.oneShot(
        "reporter",
        (deliver) => {
          deliver(undefined);
          return () => {
            canceled += 1;
          };
        },
        () => {
          throw new Error("callback failed");
        }
      );
      assert.equal(canceled, 1);
      assert.equal(logs.length, 1);
      assert.ok(logs[0]?.includes("reporter failed"));
    })
);
