// SPDX-License-Identifier: MIT
// Sequence precedence follows Krohnkite's MIT-licensed kwinshortcut/kwindriver.
import {
  type Action,
  type Config,
  parseShortcutRules,
} from "@krohnkite/config";
import type { Command, EngineEvent, EngineState } from "./types.js";

const registerActions: Partial<Readonly<Record<Action, Action>>> = {
  capacityDecrease: "capacityReset",
  decrease: "focusPrev",
  focusNext: "swapPrev",
  focusPrev: "swapNext",
  increase: "focusNext",
  moveDown: "swapNext",
  moveUp: "swapPrev",
  rotate: "rotatePart",
  rotatePart: "rotate",
};
export const registerAction = (name: Action): Action | null =>
  registerActions[name] ?? null;

export function expireRegister(
  state: EngineState,
  time: number,
  config: Config
): EngineState {
  return state.register !== state.registerMode &&
    state.registerEntered !== null &&
    time - state.shortcutTime >= config.altRegisterTimeout
    ? { ...state, register: state.registerMode, registerEntered: null }
    : state;
}

export function clearSequence(state: EngineState): EngineState {
  return {
    ...state,
    shortcutDeadline: null,
    shortcutFallback: null,
    shortcutKeys: [],
    shortcutSurfaceId: null,
  };
}

interface ShortcutResolution {
  readonly commands: readonly Command[];
  readonly name: Action | null;
  readonly state: EngineState;
}

/** A complete short sequence remains a fallback while a longer prefix can win. */
export function resolveShortcut(
  initialState: EngineState,
  input: Extract<EngineEvent, { type: "action" }>,
  config: Config
): ShortcutResolution {
  const time = input.time ?? initialState.clock;
  let state = expireRegister(initialState, time, config);
  const rules = parseShortcutRules(config);
  const single = rules.find(
    (rule) =>
      rule.shortcuts.length === 1 && rule.shortcuts[0] === input.shortcut
  );
  const main = single?.action ?? input.action;
  const alternate = single?.registerAction ?? registerAction(input.action);
  const plain = state.register ? (alternate ?? main) : main;
  const commands: Command[] = [];
  const pending = state.shortcutKeys.length > 0;
  const keys = input.shortcut ? [...state.shortcutKeys, input.shortcut] : [];
  state = { ...state, shortcutTime: time };
  if (state.register !== state.registerMode) {
    commands.push({
      deadline: time + config.altRegisterTimeout,
      type: "shortcutTimer",
    });
  }
  if (!input.shortcut) {
    return { commands, name: plain, state };
  }
  const matching = rules.filter(
    (rule) =>
      rule.shortcuts.length > 1 &&
      keys.every((name, index) => rule.shortcuts[index] === name) &&
      (!pending || time <= (initialState.shortcutDeadline ?? time))
  );
  if (pending && matching.length === 0) {
    // Upstream consumes an invalid continuation without executing either key.
    return { commands, name: null, state: clearSequence(state) };
  }
  const complete = matching.find(
    (rule) => rule.shortcuts.length === keys.length
  );
  const longer = matching.filter((rule) => rule.shortcuts.length > keys.length);
  let candidate = pending ? state.shortcutFallback : plain;
  if (complete) {
    candidate = state.register
      ? (complete.registerAction ?? complete.action)
      : complete.action;
  }
  if (longer.length > 0) {
    const deadline = time + Math.max(...matching.map((rule) => rule.timeout));
    state = {
      ...state,
      shortcutDeadline: deadline,
      shortcutFallback: candidate,
      shortcutKeys: keys,
      shortcutSurfaceId: input.surfaceId ?? state.shortcutSurfaceId,
    };
    commands.push({ deadline, type: "shortcutTimer" });
    return { commands, name: null, state };
  }
  return {
    commands,
    name: complete ? candidate : plain,
    state: clearSequence(state),
  };
}
