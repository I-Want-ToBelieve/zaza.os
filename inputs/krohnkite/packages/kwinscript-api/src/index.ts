import * as Cause from "effect/Cause";
import * as Context from "effect/Context";
import * as Data from "effect/Data";
import * as Effect from "effect/Effect";
import * as Exit from "effect/Exit";
import * as Layer from "effect/Layer";
import * as Scheduler from "effect/Scheduler";
import * as Scope from "effect/Scope";
import type { KWinApi, QtSignal } from "./types.ts";

export type {
  KWinApi,
  KWinWindow,
  Output,
  QtSignal,
  Rect,
  ShortcutEntry,
  VirtualDesktop,
  Workspace,
} from "./types.ts";

// Native callbacks finish before returning to Qt. Never implicitly schedule their
// continuation on a Promise or timer; explicit asynchronous effects still fail.
const synchronousContext = Context.make(Scheduler.PreventSchedulerYield, true);
export const runKWinSync = Effect.runSyncWith(synchronousContext);
export const runKWinSyncExit = Effect.runSyncExitWith(synchronousContext);

export class KWinApiError extends Data.TaggedError("KWinApiError")<{
  readonly operation: string;
  readonly target?: string | undefined;
  readonly cause: unknown;
}> {}

export interface KWinScriptApiOptions {
  /** Finalizers and native Qt callbacks report through their owning application. */
  readonly onError?: (error: KWinApiError) => void;
}

export interface KWinScriptApiService {
  readonly call: <A>(
    operation: string,
    thunk: () => A,
    target?: string
  ) => Effect.Effect<A, KWinApiError>;
  readonly connect: <Args extends unknown[]>(
    signal: QtSignal<Args> | undefined,
    callback: (...args: Args) => void,
    target?: string
  ) => Effect.Effect<void, KWinApiError, Scope.Scope>;
  /** Own a cancelable native callback until completion or the caller's scope ends. */
  readonly oneShot: <A>(
    operation: string,
    register: (deliver: (value: A) => void) => () => void,
    callback: (value: A) => void,
    target?: string
  ) => Effect.Effect<void, KWinApiError, Scope.Scope>;
  readonly queryVirtualKeyboard: (
    callback: (visible: boolean) => void,
    target?: string
  ) => Effect.Effect<void, KWinApiError, Scope.Scope>;
  readonly raw: KWinApi;
  readonly scheduleTimer: (
    milliseconds: number,
    callback: () => void
  ) => Effect.Effect<void, KWinApiError, Scope.Scope>;
}

/** Qt resources use the supplied native bridge; no Node or browser scheduler is installed. */
export const makeKWinScriptApi = (
  api: KWinApi,
  options: KWinScriptApiOptions = {}
): KWinScriptApiService => {
  const onError =
    options.onError ??
    ((error: KWinApiError) => {
      api.log(
        `KWinApiError ${error.operation}${error.target === undefined ? "" : ` ${error.target}`}: ${String(error.cause)}`
      );
    });
  const call = <A>(
    operation: string,
    thunk: () => A,
    target?: string
  ): Effect.Effect<A, KWinApiError> =>
    Effect.try({
      catch: (cause) => new KWinApiError({ cause, operation, target }),
      try: thunk,
    });
  const reportError = (error: KWinApiError): void => {
    const reported = runKWinSyncExit(Effect.sync(() => onError(error)));
    if (Exit.isFailure(reported)) {
      const details = reported.cause.reasons
        .map((reason) =>
          reason._tag === "Die" ? String(reason.defect) : reason._tag
        )
        .join("\n");
      api.log(
        `KWin error reporter defect: ${details}\n${Cause.pretty(reported.cause)}`
      );
    }
  };
  const cleanup = (
    operation: string,
    cancel: () => void,
    target?: string
  ): Effect.Effect<void> =>
    call(operation, cancel, target).pipe(
      Effect.catchTag("KWinApiError", (error) =>
        Effect.sync(() => reportError(error))
      )
    );
  const runCallback = (effect: Effect.Effect<unknown, KWinApiError>): void => {
    const exit = runKWinSyncExit(effect);
    if (Exit.isSuccess(exit)) {
      return;
    }
    for (const reason of exit.cause.reasons) {
      if (reason._tag === "Fail") {
        reportError(reason.error);
      } else {
        api.log(`KWin callback defect: ${Cause.pretty(exit.cause)}`);
      }
    }
  };
  const connect = <Args extends unknown[]>(
    signal: QtSignal<Args> | undefined,
    callback: (...args: Args) => void,
    target?: string
  ): Effect.Effect<void, KWinApiError, Scope.Scope> => {
    if (signal === undefined) {
      return Effect.void;
    }
    return Effect.gen(function* () {
      let active = true;
      let connected = false;
      yield* Effect.addFinalizer(() =>
        Effect.sync(() => {
          active = false;
        })
      );
      if (!active) {
        return;
      }
      const deliver = (...args: Args): void => {
        if (!active) {
          return;
        }
        runCallback(call("signal:callback", () => callback(...args), target));
      };
      yield* Effect.acquireRelease(
        call(
          "connect",
          () => {
            signal.connect(deliver);
            connected = true;
          },
          target
        ),
        () => {
          active = false;
          if (!connected) {
            return Effect.void;
          }
          connected = false;
          return cleanup(
            "disconnect",
            () => signal.disconnect(deliver),
            target
          );
        }
      ).pipe(
        Effect.onExit((exit) => {
          if (Exit.isFailure(exit)) {
            active = false;
          }
          return Effect.void;
        })
      );
    });
  };
  const oneShot = <A>(
    operation: string,
    register: (deliver: (value: A) => void) => () => void,
    callback: (value: A) => void,
    target?: string
  ): Effect.Effect<void, KWinApiError, Scope.Scope> =>
    Effect.gen(function* () {
      const parent = yield* Effect.scope;
      const child = yield* Scope.fork(parent);
      let active = true;
      yield* Scope.addFinalizer(
        child,
        Effect.sync(() => {
          active = false;
        })
      );
      if (!active) {
        return;
      }
      const deliver = (value: A): void => {
        if (!active) {
          return;
        }
        active = false;
        runCallback(
          call(`${operation}:callback`, () => callback(value), target).pipe(
            Effect.ensuring(Scope.close(child, Exit.void))
          )
        );
      };
      yield* Scope.provide(
        Effect.acquireRelease(
          call(operation, () => register(deliver), target),
          (cancel) => {
            active = false;
            return cleanup(`cancel:${operation}`, cancel, target);
          }
        ),
        child
      ).pipe(
        Effect.onExit((exit) => {
          if (Exit.isSuccess(exit)) {
            return Effect.void;
          }
          active = false;
          return Scope.close(child, exit);
        })
      );
    });
  const scheduleTimer = (
    milliseconds: number,
    callback: () => void
  ): Effect.Effect<void, KWinApiError, Scope.Scope> => {
    const schedule = api.scheduleTimer;
    if (schedule === undefined) {
      return Effect.fail(
        new KWinApiError({
          cause: "QML timer bridge is unavailable",
          operation: "timer",
        })
      );
    }
    return oneShot(
      "timer",
      (deliver) => schedule(milliseconds, () => deliver(undefined)),
      callback
    );
  };
  const queryVirtualKeyboard = (
    callback: (visible: boolean) => void,
    target?: string
  ): Effect.Effect<void, KWinApiError, Scope.Scope> => {
    const query = api.queryVirtualKeyboard;
    if (query === undefined) {
      return Effect.fail(
        new KWinApiError({
          cause: "QML DBus bridge is unavailable",
          operation: "virtualKeyboard",
          target,
        })
      );
    }
    return oneShot("virtualKeyboard", query, callback, target);
  };
  return {
    call,
    connect,
    oneShot,
    queryVirtualKeyboard,
    raw: api,
    scheduleTimer,
  };
};

export class KWinScriptApi extends Context.Service<
  KWinScriptApi,
  KWinScriptApiService
>()("krohnkite/KWinScriptApi") {
  static layer(
    api: KWinApi,
    options?: KWinScriptApiOptions
  ): Layer.Layer<KWinScriptApi> {
    return Layer.succeed(KWinScriptApi, makeKWinScriptApi(api, options));
  }
}
