import { readFileSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join } from "node:path";
import { runInNewContext } from "node:vm";
import { parse } from "acorn";
import { Cause, Effect, Exit } from "effect";
import { expect, it } from "vitest";
import {
  assertQtGeneratorsLowered,
  deferEffectBigInt,
  lowerQtGenerators,
  qtBanner,
} from "./effect-qt.ts";

const unavailableBigIntPattern = /BigInt time features are unavailable/;
const upgradeGuardPattern = /review Effect before upgrading/;
const symbolCopyPrelude = `
Object.assign = function(target, source) { for (var key of Object.keys(source)) target[key] = source[key]; return target; };
Object.defineProperties = function(target, descriptors) { for (var key of Object.keys(descriptors)) Object.defineProperty(target, key, descriptors[key]); return target; };
`;

const runQtCompatibility = (source: string): unknown =>
  runInNewContext(`${symbolCopyPrelude}${qtBanner}\n${source}`);

const durationFixture = [
  "const bigint0 = BigInt(0);",
  "const bigint1 = BigInt(1);",
  "const bigint2 = BigInt(2);",
  "const bigint10 = BigInt(10);",
  "const bigint24 = BigInt(24);",
  "const bigint60 = BigInt(60);",
  "const bigint1e3 = BigInt(1000);",
  "const bigint1e6 = BigInt(1000000);",
  "const bigint1e9 = BigInt(1000000000);",
  "const exact = () => (bigint1e9 * bigint1e9 + bigint1) / bigint1;",
  "({ exact });",
].join("\n");

it("lazy BigInt preserves precision beyond Number and fails only on use in Qt", () => {
  const transformed = deferEffectBigInt(durationFixture, "Duration");
  const native = runInNewContext(transformed) as { exact: () => bigint };
  expect(native.exact()).toBe(1_000_000_000_000_000_001n);
  const qt = runInNewContext(transformed, { BigInt: undefined }) as {
    exact: () => bigint;
  };
  expect(() => qt.exact()).toThrow(unavailableBigIntPattern);
});

it("clock IIFEs and noop span status are not initialized by loading Qt bundle", () => {
  const fixture = `
let initialized = 0;
const bigint0 = BigInt(0);
const NoopSpanProto = { status: { startTime: bigint0, endTime: bigint0 } };
const nanosPerMilli = BigInt(1000000);
const monotonicNowNanos = (function() { initialized++; let previous = BigInt(0); return () => ++previous; })();
const wallTimeNanos = (function() { initialized++; const scale = nanosPerMilli; return () => monotonicNowNanos() * scale; })();
({ count: () => initialized, wall: () => wallTimeNanos(), span: () => NoopSpanProto });`;
  const code = deferEffectBigInt(fixture, "internal/effect");
  const native = runInNewContext(code) as {
    count: () => number;
    wall: () => bigint;
    span: () => { status: { startTime: bigint } };
  };
  expect(native.count()).toBe(0);
  expect(native.wall()).toBe(1_000_000n);
  expect(native.wall()).toBe(2_000_000n);
  expect(native.count()).toBe(2);
  expect(native.span().status.startTime).toBe(0n);
  const qt = runInNewContext(code, { BigInt: undefined }) as {
    count: () => number;
    wall: () => bigint;
  };
  expect(qt.count()).toBe(0);
  expect(() => qt.wall()).toThrow(unavailableBigIntPattern);
});

it("transformation validates the actual locked Effect sources", () => {
  const require = createRequire(import.meta.url);
  const duration = require.resolve("effect/Duration");
  const internal = join(dirname(duration), "internal", "effect.js");
  for (const [path, kind] of [
    [duration, "Duration"],
    [internal, "internal/effect"],
  ] as const) {
    const transformed = deferEffectBigInt(readFileSync(path, "utf8"), kind);
    expect(() =>
      parse(transformed, { ecmaVersion: "latest", sourceType: "module" })
    ).not.toThrow();
  }
  expect(() =>
    deferEffectBigInt("const bigint0 = BigInt(0)", "Duration")
  ).toThrow(upgradeGuardPattern);
});

it("Qt compatibility helpers retain safe own-property semantics", () => {
  const result =
    runInNewContext(`Object.fromEntries = undefined; Object.hasOwn = undefined; ${qtBanner}
Object.hasOwn(Object.fromEntries([["__proto__", 17]]), "__proto__")`);
  expect(result).toBe(true);
});

it("Qt symbol-copy compatibility preserves iterators and descriptor atomicity", () => {
  const result = runInNewContext(`
Object.assign = function(target, source) { for (var key of Object.keys(source)) target[key] = source[key]; return target; };
Object.defineProperties = function(target, descriptors) { for (var key of Object.keys(descriptors)) Object.defineProperty(target, key, descriptors[key]); return target; };
${qtBanner}
var symbol = Symbol("iterator");
var source = {}; source[symbol] = 21;
var assigned = Object.assign({}, source);
var defined = Object.defineProperties({}, Object.getOwnPropertyDescriptors(source));
var untouched = {};
try { Object.defineProperties(untouched, { first: { value: 3 }, second: 17 }); } catch (error) {}
({ assigned: assigned[symbol], defined: defined[symbol], unchanged: !Object.hasOwn(untouched, "first") });
`) as { assigned: number; defined: number; unchanged: boolean };
  expect(result.assigned).toBe(21);
  expect(result.defined).toBe(21);
  expect(result.unchanged).toBe(true);
});

it("Qt compatibility works when native Object static properties are immutable", () => {
  const result = runInNewContext(`
var nativeObject = ({}).constructor;
nativeObject.defineProperty(nativeObject, "assign", { value: function(target, source) { for (var key of nativeObject.keys(source)) target[key] = source[key]; return target; }, writable: false, configurable: false });
nativeObject.defineProperty(nativeObject, "defineProperties", { value: function(target, descriptors) { for (var key of nativeObject.keys(descriptors)) nativeObject.defineProperty(target, key, descriptors[key]); return target; }, writable: false, configurable: false });
var before = nativeObject.assign;
${qtBanner}
var symbol = Symbol.iterator;
var source = {}; source[symbol] = function() {};
var assigned = Object.assign({}, source);
var defined = Object.defineProperties({}, Object.getOwnPropertyDescriptors(source));
({ assigned: typeof assigned[symbol], defined: typeof defined[symbol], unchanged: nativeObject.assign === before, facade: Object !== nativeObject });
`) as {
    assigned: string;
    defined: string;
    unchanged: boolean;
    facade: boolean;
  };
  expect(result.assigned).toBe("function");
  expect(result.defined).toBe("function");
  expect(result.unchanged).toBe(true);
  expect(result.facade).toBe(true);
});

it("Qt defineProperties retains omitted data flags and an existing accessor", () => {
  const result = runQtCompatibility(`
var target = { data: 1 };
var getter = function() { return 17; };
var setter = function(value) { target.stored = value; };
Object.defineProperty(target, "accessor", { get: getter, configurable: true, enumerable: true });
Object.defineProperties(target, { data: { value: 2 }, accessor: { set: setter } });
target.accessor = 9;
({ data: Object.getOwnPropertyDescriptor(target, "data"), accessor: Object.getOwnPropertyDescriptor(target, "accessor"), getterPreserved: Object.getOwnPropertyDescriptor(target, "accessor").get === getter, getterValue: target.accessor, stored: target.stored });
`) as {
    data: PropertyDescriptor;
    accessor: PropertyDescriptor;
    getterPreserved: boolean;
    getterValue: number;
    stored: number;
  };
  expect(result.data).toEqual({
    configurable: true,
    enumerable: true,
    value: 2,
    writable: true,
  });
  expect(result.accessor.enumerable).toBe(true);
  expect(result.accessor.configurable).toBe(true);
  expect(result.getterPreserved).toBe(true);
  expect(result.getterValue).toBe(17);
  expect(result.stored).toBe(9);
});

it("Qt descriptor conversion reads inherited fields once in specification order", () => {
  const result = runQtCompatibility(`
var reads = [];
var inherited = {};
for (let name of ["enumerable", "configurable", "value", "writable", "get", "set"]) {
  Object.defineProperty(inherited, name, { get: function() { reads.push(name); return name === "value" ? 7 : undefined; } });
}
var descriptors = {};
Object.defineProperty(descriptors, "first", { enumerable: true, get: function() { reads.push("first"); return Object.create(inherited); } });
var target = {};
var rejected = false;
try { Object.defineProperties(target, descriptors); } catch (error) { rejected = error instanceof TypeError; }
({ reads: reads, rejected: rejected, unchanged: !Object.hasOwn(target, "first") });
`) as { reads: string[]; rejected: boolean; unchanged: boolean };
  expect(result.reads).toEqual([
    "first",
    "enumerable",
    "configurable",
    "value",
    "writable",
    "get",
    "set",
  ]);
  expect(result.rejected).toBe(true);
  expect(result.unchanged).toBe(true);
});

it("Qt defineProperties observes later keys after earlier descriptor getters", () => {
  const result = runQtCompatibility(`
var reads = [];
var descriptors = {};
Object.defineProperty(descriptors, "first", { enumerable: true, get: function() {
  reads.push("first");
  Object.defineProperty(descriptors, "second", { enumerable: false });
  return { value: 3, enumerable: true };
} });
Object.defineProperty(descriptors, "second", { configurable: true, enumerable: true, get: function() { reads.push("second"); return { value: 4 }; } });
var target = Object.defineProperties({}, descriptors);
({ reads: reads, first: target.first, skipped: !Object.hasOwn(target, "second") });
`) as { reads: string[]; first: number; skipped: boolean };
  expect(result.reads).toEqual(["first"]);
  expect(result.first).toBe(3);
  expect(result.skipped).toBe(true);
});

it("Qt defineProperties validates all descriptors before mutating the target", () => {
  const result = runQtCompatibility(`
var invalid = [17, null, { get: 17 }, { set: 17 }, { value: 1, get: undefined }, { writable: false, set: undefined }];
var outcomes = [];
for (var descriptor of invalid) {
  var target = { first: 1 };
  var rejected = false;
  try { Object.defineProperties(target, { first: { value: 2 }, second: descriptor }); } catch (error) { rejected = error instanceof TypeError; }
  outcomes.push(rejected && target.first === 1 && !Object.hasOwn(target, "second"));
}
outcomes;
`) as boolean[];
  expect(result).toEqual([true, true, true, true, true, true]);
});

it("lowered Effect.gen retains yield delegation, loop bindings and destructuring", () => {
  const source = `
Effect.gen(function*() {
  let total = 0;
  const callbacks = [];
  for (const [index, value] of [[1, 2], [3, 4]]) {
    const { doubled } = yield* Effect.sync(() => ({ doubled: value * 2 }));
    total += index + doubled;
    callbacks.push(() => value);
  }
  return { total, captured: callbacks.map(callback => callback()) };
});`;
  const transformed = lowerQtGenerators(source, "effect-loop.js");
  const program = runInNewContext(transformed.code, {
    Effect,
  }) as Effect.Effect<{
    total: number;
    captured: number[];
  }>;
  expect(Effect.runSync(program)).toEqual({ captured: [2, 4], total: 16 });
  expect(() => assertQtGeneratorsLowered(transformed.code)).not.toThrow();
  expect(transformed.map.sources).toEqual(["effect-loop.js"]);
  expect(transformed.map.sourcesContent).toEqual([source]);
  expect(transformed.map.mappings.length).toBeGreaterThan(0);
});

it("lowered delegated iterators preserve throw, return and finally semantics", () => {
  const source = `
var events = [];
function* delegate() {
  try { yield "first"; yield "second"; return 3; }
  finally { events.push("delegate finally"); }
}
function* program() {
  try { return yield* delegate(); }
  catch (error) { events.push(error.message); return 42; }
  finally { events.push("program finally"); }
}
({ events, program });`;
  const lowered = lowerQtGenerators(source, "iterator-cleanup.js");
  const thrown = runInNewContext(lowered.code) as {
    events: string[];
    program: () => Generator<string, number>;
  };
  const iterator = thrown.program();
  expect(iterator.next()).toEqual({ done: false, value: "first" });
  expect(iterator.throw(new Error("injected"))).toEqual({
    done: true,
    value: 42,
  });
  expect(thrown.events).toEqual([
    "delegate finally",
    "injected",
    "program finally",
  ]);
  const returned = runInNewContext(lowered.code) as typeof thrown;
  const early = returned.program();
  early.next();
  expect(early.return(9)).toEqual({ done: true, value: 9 });
  expect(returned.events).toEqual(["delegate finally", "program finally"]);
});

it("lowered Effect.gen releases scoped resources on success and typed failure", () => {
  const source = `
var events = [];
function make(fail) {
  return Effect.scoped(Effect.gen(function*() {
    const window = yield* Effect.acquireRelease(
      Effect.sync(() => { events.push("acquire"); return "window"; }),
      () => Effect.sync(() => { events.push("release"); })
    );
    if (fail) return yield* Effect.fail("configuration unavailable");
    return window;
  }));
}
({ events, make });`;
  const lowered = lowerQtGenerators(source, "scoped-effect.js");
  const runtime = runInNewContext(lowered.code, { Effect }) as {
    events: string[];
    make: (fail: boolean) => Effect.Effect<string, string>;
  };
  expect(Effect.runSync(runtime.make(false))).toBe("window");
  expect(runtime.events).toEqual(["acquire", "release"]);
  const failed = Effect.runSyncExit(runtime.make(true));
  expect(Exit.isFailure(failed)).toBe(true);
  if (Exit.isFailure(failed)) {
    expect(Cause.pretty(failed.cause)).toContain("configuration unavailable");
  }
  expect(runtime.events).toEqual(["acquire", "release", "acquire", "release"]);
});

it("Qt lowering preserves ordinary lexical loops and rejects native generator syntax", () => {
  const source = `
function ordinary(values) {
  const callbacks = [];
  for (const [value] of values) callbacks.push(() => value);
  return callbacks.map(callback => callback());
}
ordinary([[1], [2]]);`;
  const lowered = lowerQtGenerators(source, "ordinary-loop.js");
  expect(lowered.code).toContain("for (const [value] of values)");
  expect(runInNewContext(lowered.code)).toEqual([1, 2]);
  for (const native of [
    "function* generator() { yield 1; }",
    "async function waiting() { await Promise.resolve(); }",
  ]) {
    expect(() => assertQtGeneratorsLowered(native)).toThrow(
      "native generator or await remains"
    );
  }
});
