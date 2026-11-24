import type { Config } from "@krohnkite/config";
import {
  type Command,
  createState,
  type EngineEvent,
  type EngineState,
  reduce,
} from "@krohnkite/core";
import * as Cause from "effect/Cause";
import * as Context from "effect/Context";
import * as Data from "effect/Data";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Ref from "effect/Ref";
import * as Scheduler from "effect/Scheduler";
import * as Scope from "effect/Scope";

const synchronousContext = Context.make(Scheduler.PreventSchedulerYield, true);
const runSync = Effect.runSyncWith(synchronousContext);
const runSyncExit = Effect.runSyncExitWith(synchronousContext);

/** Failures of the external compositor boundary retain their operation and target. */
export class CompositorError extends Data.TaggedError("CompositorError")<{
  readonly operation: string;
  readonly target?: string | undefined;
  readonly cause: unknown;
}> {}

const describeError = (error: unknown, depth = 0): string => {
  if (depth > 3) {
    return "nested error";
  }
  if (error instanceof CompositorError) {
    return `CompositorError ${error.operation}${error.target === undefined ? "" : ` ${error.target}`}: ${describeError(error.cause, depth + 1)}`;
  }
  if (error instanceof Error) {
    return `${error.name}: ${error.message}\n${error.stack ?? ""}`;
  }
  return String(error);
};

/** QV4 Error.stack contains frames without the message, unlike Node/V8. */
export const formatCause = <E>(cause: Cause.Cause<E>): string => {
  const details = cause.reasons
    .map((reason) => {
      if (reason._tag === "Fail") {
        return describeError(reason.error);
      }
      if (reason._tag === "Die") {
        return describeError(reason.defect);
      }
      return "Effect interrupted";
    })
    .join("\n");
  return `${details}\n${Cause.pretty(cause)}`;
};

export interface HostService {
  readonly apply: (command: Command) => Effect.Effect<void, CompositorError>;
  readonly observe: (
    send: (event: EngineEvent) => void
  ) => Effect.Effect<void, CompositorError, Scope.Scope>;
  readonly report: (message: string) => void;
}

export class Compositor extends Context.Service<Compositor, HostService>()(
  "krohnkite/Compositor"
) {}

export interface EngineService {
  readonly configure: (config: Config) => Effect.Effect<void, CompositorError>;
  readonly dispatch: (
    event: EngineEvent
  ) => Effect.Effect<void, CompositorError>;
  readonly snapshot: Effect.Effect<EngineState>;
}

export class Engine extends Context.Service<Engine, EngineService>()(
  "krohnkite/Engine"
) {}

/** Mutable application state lives in Effect; the reducer itself stays pure. */
export const makeEngine = (
  initialConfig: Config
): Effect.Effect<EngineService, never, Compositor> =>
  Effect.gen(function* () {
    const host = yield* Compositor;
    const state = yield* Ref.make(createState(initialConfig));
    const config = yield* Ref.make(initialConfig);
    const dispatch = (event: EngineEvent) =>
      Effect.gen(function* () {
        const current = yield* Ref.get(state);
        const settings = yield* Ref.get(config);
        const next = reduce(current, event, settings);
        // Commit before talking to KWin: property setters can synchronously emit signals.
        yield* Ref.set(state, next.state);
        for (const command of next.commands) {
          yield* host.apply(command);
        }
      });
    return {
      configure: (settings: Config) =>
        Effect.gen(function* () {
          yield* Ref.set(config, settings);
          yield* dispatch({ type: "arrange" });
        }),
      dispatch,
      snapshot: Ref.get(state),
    };
  });

export interface EngineRuntime {
  readonly configure: (config: Config) => boolean;
  readonly dispose: () => void;
  readonly isRunning: () => boolean;
  readonly send: (event: EngineEvent) => void;
  readonly snapshot: () => EngineState | null;
  readonly start: () => boolean;
}

/**
 * Qt callbacks are synchronous. A guarded FIFO serializes them and prevents
 * geometry notifications raised during a command from recursively reducing state.
 * No Promise, browser timer, or Node platform runtime is needed here.
 */
export const createEngineRuntime = (
  initialConfig: Config,
  host: HostService
): EngineRuntime => {
  let scope: Scope.Closeable | null = null;
  let engine: EngineService | null = null;
  let disposed = false;
  let draining = false;
  const events: EngineEvent[] = [];

  const reportExit = <A, E>(exit: Exit.Exit<A, E>): boolean => {
    if (Exit.isFailure(exit)) {
      host.report(formatCause(exit.cause));
      return false;
    }
    return true;
  };

  const send = (event: EngineEvent): void => {
    if (disposed || engine === null) {
      return;
    }
    events.push(event);
    if (draining) {
      return;
    }
    draining = true;
    // Errors are reported at the sole runtime boundary; later events still run.
    while (events.length > 0 && !disposed) {
      const next = events.shift();
      if (next !== undefined) {
        reportExit(runSyncExit(engine.dispatch(next)));
      }
    }
    draining = false;
  };

  return {
    configure: (settings) =>
      engine !== null && reportExit(runSyncExit(engine.configure(settings))),
    dispose: () => {
      if (disposed) {
        return;
      }
      disposed = true;
      events.length = 0;
      engine = null;
      if (scope !== null) {
        const closing = scope;
        scope = null;
        reportExit(runSyncExit(Scope.close(closing, Exit.void)));
      }
    },
    isRunning: () => engine !== null && !disposed,
    send,
    snapshot: () => (engine === null ? null : runSync(engine.snapshot)),
    start: () => {
      if (disposed) {
        return false;
      }
      if (engine !== null) {
        return true;
      }
      const acquired = runSyncExit(Scope.make());
      if (!reportExit(acquired) || Exit.isFailure(acquired)) {
        return false;
      }
      const nextScope = acquired.value;
      scope = nextScope;
      let phase = "engine services";
      const boot = Effect.gen(function* () {
        engine = yield* makeEngine(initialConfig).pipe(
          Effect.provideService(Compositor, host)
        );
        phase = "compositor observers";
        yield* host.observe(send);
      });
      const started = runSyncExit(Scope.provide(boot, nextScope));
      if (Exit.isFailure(started)) {
        host.report(`initialization failed during ${phase}`);
      }
      if (reportExit(started)) {
        return true;
      }
      engine = null;
      scope = null;
      events.length = 0;
      reportExit(runSyncExit(Scope.close(nextScope, started)));
      return false;
    },
  };
};
