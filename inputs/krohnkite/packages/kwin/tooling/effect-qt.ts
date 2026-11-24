import { transformSync } from "@babel/core";
import blockScoping from "@babel/plugin-transform-block-scoping";
import destructuring from "@babel/plugin-transform-destructuring";
import forOf from "@babel/plugin-transform-for-of";
import regenerator from "@babel/plugin-transform-regenerator";
import { type Node, parse } from "acorn";

const field = (node: Node, key: string): unknown => Reflect.get(node, key);
const isNode = (value: unknown): value is Node =>
  typeof value === "object" &&
  value !== null &&
  typeof Reflect.get(value, "type") === "string" &&
  typeof Reflect.get(value, "start") === "number" &&
  typeof Reflect.get(value, "end") === "number";
const identifier = (value: unknown): string | undefined => {
  if (!isNode(value) || value.type !== "Identifier") {
    return undefined;
  }
  const name = field(value, "name");
  return typeof name === "string" ? name : undefined;
};

interface Edit {
  readonly end: number;
  readonly start: number;
  readonly text: string;
}
interface LazyBinding {
  readonly bigint: boolean;
  readonly declaration: Node;
  readonly initializer: Node;
  readonly name: string;
}

type EffectModule = "Duration" | "internal/effect";
const effectModulePattern = /\/effect\/dist\/(Duration|internal\/effect)\.js$/;

const bindingFrom = (
  declaration: Node,
  kind: EffectModule
): LazyBinding | undefined => {
  const name = identifier(field(declaration, "id"));
  const initializer = field(declaration, "init");
  if (name === undefined || !isNode(initializer)) {
    return undefined;
  }
  const bigint =
    initializer.type === "CallExpression" &&
    identifier(field(initializer, "callee")) === "BigInt";
  const clock =
    kind === "internal/effect" &&
    ["monotonicNowNanos", "wallTimeNanos", "NoopSpanProto"].includes(name);
  return bigint || clock
    ? { bigint, declaration, initializer, name }
    : undefined;
};

const moduleBindings = (ast: Node, kind: EffectModule): LazyBinding[] => {
  const body = field(ast, "body");
  if (!Array.isArray(body)) {
    throw new Error("Effect Qt transform: missing module body");
  }
  const bindings: LazyBinding[] = [];
  for (const statement of body) {
    if (!isNode(statement) || statement.type !== "VariableDeclaration") {
      continue;
    }
    const declarations = field(statement, "declarations");
    if (!Array.isArray(declarations)) {
      continue;
    }
    for (const declaration of declarations) {
      if (!isNode(declaration)) {
        continue;
      }
      const binding = bindingFrom(declaration, kind);
      if (binding !== undefined) {
        bindings.push(binding);
      }
    }
  }
  return bindings;
};

const propertyName = (
  parent: Node | undefined,
  key: string | undefined
): boolean => {
  if (parent === undefined || field(parent, "computed") === true) {
    return false;
  }
  return (
    (parent.type === "MemberExpression" && key === "property") ||
    (parent.type === "Property" && key === "key")
  );
};

const bindingName = (
  parent: Node | undefined,
  key: string | undefined
): boolean => {
  if (parent === undefined) {
    return false;
  }
  if (parent.type === "VariableDeclarator") {
    return key === "id";
  }
  const callable = [
    "FunctionDeclaration",
    "FunctionExpression",
    "ArrowFunctionExpression",
  ].includes(parent.type);
  return callable && (key === "id" || key === "params");
};

const walk = (
  node: Node,
  visitor: (node: Node, parent?: Node, key?: string) => void,
  parent?: Node,
  key?: string
): void => {
  visitor(node, parent, key);
  for (const [childKey, value] of Object.entries(node)) {
    if (Array.isArray(value)) {
      for (const child of value) {
        if (isNode(child)) {
          walk(child, visitor, node, childKey);
        }
      }
    } else if (isNode(value)) {
      walk(value, visitor, node, childKey);
    }
  }
};

const bindingReferences = (
  ast: Node,
  bindings: readonly LazyBinding[]
): Edit[] => {
  const byName = new Map(bindings.map((binding) => [binding.name, binding]));
  const references: Edit[] = [];
  walk(ast, (node, parent, key) => {
    const name = identifier(node);
    if (name === undefined) {
      return;
    }
    const binding = byName.get(name);
    if (binding === undefined || node === field(binding.declaration, "id")) {
      return;
    }
    if (bindingName(parent, key)) {
      throw new Error(`Effect Qt transform: shadowed binding ${binding.name}`);
    }
    if (propertyName(parent, key)) {
      return;
    }
    const shorthand =
      parent?.type === "Property" && field(parent, "shorthand") === true;
    references.push({
      end: node.end,
      start: node.start,
      text: shorthand ? `${name}: ${name}()` : `${name}()`,
    });
  });
  return references;
};

/**
 * Effect 4.0.0 initializes unused BigInt clocks when imported. Qt's QV4 has no
 * BigInt. Laziness leaves exact native BigInt arithmetic intact and raises a
 * clear error if the Qt application ever requests that unsupported feature.
 * Only the locked Effect dependency is transformed; its submodule is untouched.
 */
export function deferEffectBigInt(source: string, kind: EffectModule): string {
  const ast = parse(source, { ecmaVersion: "latest", sourceType: "module" });
  const bindings = moduleBindings(ast, kind);
  const expected =
    kind === "Duration"
      ? [
          "bigint0",
          "bigint1",
          "bigint2",
          "bigint10",
          "bigint24",
          "bigint60",
          "bigint1e3",
          "bigint1e6",
          "bigint1e9",
        ]
      : [
          "bigint0",
          "NoopSpanProto",
          "nanosPerMilli",
          "monotonicNowNanos",
          "wallTimeNanos",
        ];
  if (
    bindings
      .map((binding) => binding.name)
      .sort((left, right) => left.localeCompare(right))
      .join(",") !==
    [...expected].sort((left, right) => left.localeCompare(right)).join(",")
  ) {
    throw new Error(
      `Effect Qt transform: ${kind} initialization changed; review Effect before upgrading`
    );
  }
  // Inserts wrap existing initializers, so identifier edits within them remain disjoint.
  const edits: Edit[] = bindingReferences(ast, bindings);
  for (const binding of bindings) {
    const guard = binding.bigint
      ? "if (typeof BigInt !== 'function') throw new Error('Krohnkite: Effect BigInt time features are unavailable in Qt QV4'); "
      : "";
    edits.push({
      end: binding.initializer.start,
      start: binding.initializer.start,
      text: `__krohnkiteQtLazy(() => { ${guard}return (`,
    });
    edits.push({
      end: binding.initializer.end,
      start: binding.initializer.end,
      text: "); })",
    });
  }
  edits.sort((left, right) => right.start - left.start || right.end - left.end);
  let code = source;
  for (const edit of edits) {
    code = `${code.slice(0, edit.start)}${edit.text}${code.slice(edit.end)}`;
  }
  return `const __krohnkiteQtLazy = (make) => { let ready = false; let value; return () => { if (!ready) { value = make(); ready = true; } return value; }; };\n${code}`;
}

export function assertQtGeneratorsLowered(source: string): void {
  const ast = parse(source, { ecmaVersion: "latest", sourceType: "script" });
  walk(ast, (node) => {
    if (
      field(node, "generator") === true ||
      node.type === "YieldExpression" ||
      node.type === "AwaitExpression"
    ) {
      throw new Error(
        "Effect Qt transform: native generator or await remains in the Qt bundle"
      );
    }
  });
}

const sourceMapStrings = (values: readonly (string | null)[]): string[] =>
  values.map((value) => {
    if (value === null) {
      throw new Error(
        "Effect Qt transform: source map has missing source content"
      );
    }
    return value;
  });

/**
 * Qt 6.11.2 crashes during GC under sustained native-generator acquisition.
 * Lower the final Qt chunk to state machines while preserving iterator cleanup.
 * The prerequisites are limited to generator bodies; normal bundle loops keep
 * their lexical bindings. Rolldown composes the returned map with package maps.
 */
export function lowerQtGenerators(source: string, filename: string) {
  const options = {
    babelrc: false,
    comments: true,
    compact: false,
    configFile: false,
    filename,
    sourceFileName: filename,
    sourceMaps: true,
    sourceType: "script" as const,
  };
  const prerequisites = transformSync(source, {
    ...options,
    plugins: [forOf, destructuring, blockScoping],
    wrapPluginVisitorMethod(_plugin, _phase, callback) {
      return function (path, state) {
        if (
          (path.isFunction() && path.node.generator === true) ||
          path.getFunctionParent()?.node.generator === true
        ) {
          return callback.call(this, path, state);
        }
      };
    },
  });
  if (
    prerequisites === null ||
    prerequisites.code === null ||
    prerequisites.map === null
  ) {
    throw new Error(
      "Effect Qt transform: generator prerequisites returned no map"
    );
  }
  const transformed = transformSync(prerequisites.code, {
    ...options,
    inputSourceMap: {
      file: filename,
      mappings: prerequisites.map.mappings,
      names: [...prerequisites.map.names],
      sources: sourceMapStrings(prerequisites.map.sources),
      version: prerequisites.map.version,
      ...(prerequisites.map.sourcesContent === undefined
        ? {}
        : {
            sourcesContent: sourceMapStrings(prerequisites.map.sourcesContent),
          }),
      ...(prerequisites.map.sourceRoot === undefined
        ? {}
        : { sourceRoot: prerequisites.map.sourceRoot }),
    },
    plugins: [
      [regenerator, { async: true, asyncGenerators: true, generators: true }],
    ],
  });
  if (
    transformed === null ||
    transformed.code === null ||
    transformed.map === null
  ) {
    throw new Error("Effect Qt transform: generator lowering returned no map");
  }
  assertQtGeneratorsLowered(transformed.code);
  return { code: transformed.code, map: transformed.map };
}

export const effectQtPlugin = () => ({
  name: "krohnkite-effect-qt",
  renderChunk(source: string, chunk: { readonly fileName: string }) {
    return lowerQtGenerators(source, chunk.fileName);
  },
  transform(source: string, id: string) {
    const normalized = id.replaceAll("\\", "/").split("?")[0] ?? id;
    const match = effectModulePattern.exec(normalized);
    if (match === null) {
      return null;
    }
    const [, kind] = match;
    if (kind !== "Duration" && kind !== "internal/effect") {
      throw new Error("Unexpected Effect module");
    }
    return { code: deferEffectBigInt(source, kind), map: null };
  },
});

/** QML .js files permit creating this script-local global before bundled imports. */
export const qtBanner = `var Object = (function(NativeObject) {
  var Facade = function(value) { return NativeObject(value); };
  Facade.prototype = NativeObject.prototype;
  for (var key of Reflect.ownKeys(NativeObject)) {
    if (key === "prototype") continue;
    var descriptor = NativeObject.getOwnPropertyDescriptor(NativeObject, key);
    NativeObject.defineProperty(Facade, key, { value: NativeObject[key], writable: true, enumerable: descriptor.enumerable, configurable: true });
  }
  return Facade;
})(({}).constructor);
var globalThis = typeof globalThis !== "undefined" ? globalThis : {
  Error: Error, TypeError: TypeError, RangeError: RangeError, Object: Object,
  Symbol: Symbol, Promise: Promise, Map: Map, Set: Set, WeakMap: WeakMap, WeakSet: WeakSet,
  Array: Array, Date: Date, Math: Math, JSON: JSON, console: console
};
if (!Object.fromEntries) Object.fromEntries = function(entries) {
  var result = {}; for (var entry of entries) Object.defineProperty(result, entry[0], { value: entry[1], writable: true, enumerable: true, configurable: true }); return result;
};
if (!Object.hasOwn) Object.hasOwn = function(object, key) { return Object.prototype.hasOwnProperty.call(object, key); };
(function() {
  var probe = Symbol("krohnkite-qt-symbol-copy");
  var sample = {};
  Object.defineProperty(sample, probe, { value: 1, enumerable: true });
  function toPropertyDescriptor(input) {
    if (input === null || (typeof input !== "object" && typeof input !== "function")) throw new TypeError("Property descriptor must be an object");
    var descriptor = Object.create(null);
    if ("enumerable" in input) descriptor.enumerable = !!input.enumerable;
    if ("configurable" in input) descriptor.configurable = !!input.configurable;
    if ("value" in input) descriptor.value = input.value;
    if ("writable" in input) descriptor.writable = !!input.writable;
    if ("get" in input) {
      var getter = input.get;
      if (getter !== undefined && typeof getter !== "function") throw new TypeError("Property getter must be callable");
      descriptor.get = getter;
    }
    if ("set" in input) {
      var setter = input.set;
      if (setter !== undefined && typeof setter !== "function") throw new TypeError("Property setter must be callable");
      descriptor.set = setter;
    }
    if (("get" in descriptor || "set" in descriptor) && ("value" in descriptor || "writable" in descriptor)) throw new TypeError("Property descriptor cannot contain both accessors and a value or writable flag");
    return descriptor;
  }
  if (Object.assign({}, sample)[probe] !== 1) Object.assign = function(target) {
    "use strict";
    if (target === null || target === undefined) throw new TypeError("Object.assign target must not be null");
    var result = Object(target);
    for (var index = 1; index < arguments.length; index++) {
      var source = arguments[index];
      if (source === null || source === undefined) continue;
      source = Object(source);
      var keys = Reflect.ownKeys(source);
      for (var key of keys) {
        var descriptor = Object.getOwnPropertyDescriptor(source, key);
        if (descriptor && descriptor.enumerable) result[key] = source[key];
      }
    }
    return result;
  };
  var descriptors = {};
  Object.defineProperty(descriptors, probe, { value: { value: 1 }, enumerable: true });
  if (Object.defineProperties({}, descriptors)[probe] !== 1) Object.defineProperties = function(target, properties) {
    if (target === null || (typeof target !== "object" && typeof target !== "function")) throw new TypeError("Object.defineProperties target must be an object");
    if (properties === null || properties === undefined) throw new TypeError("Object.defineProperties descriptors must not be null");
    var source = Object(properties);
    var keys = Reflect.ownKeys(source);
    var converted = [];
    // Preserve omitted fields while validating every descriptor before writing target.
    for (var key of keys) {
      var ownDescriptor = Object.getOwnPropertyDescriptor(source, key);
      if (ownDescriptor && ownDescriptor.enumerable) converted.push([key, toPropertyDescriptor(source[key])]);
    }
    for (var entry of converted) Object.defineProperty(target, entry[0], entry[1]);
    return target;
  };
})();
`;
