import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { runInNewContext } from "node:vm";
import { parse } from "acorn";
import { strFromU8, unzipSync } from "fflate";

const root = resolve(import.meta.dirname, "..");
const dist = join(root, "dist");
const filenames = await readdir(dist);
const scripts = filenames.filter((name) => name.endsWith(".kwinscript"));
assert.equal(scripts.length, 1, "Exactly one installable script must be built");
const archive = unzipSync(await readFile(join(dist, scripts[0] ?? "")));
const entry = (filename: string): Uint8Array => {
  const content = archive[filename];
  assert(content, `Missing KWin package file: ${filename}`);
  return content;
};
for (const filename of [
  "metadata.json",
  "contents/ui/main.qml",
  "contents/ui/shortcuts.qml",
  "contents/config/main.xml",
  "contents/code/krohnkite.js",
  "LICENSE",
  "NOTICE",
  "licenses/Babel-helpers-LICENSE.txt",
  "licenses/Effect-LICENSE.txt",
  "licenses/Krohnkite-LICENSE.txt",
  "upstreams.json",
]) {
  assert(archive[filename], `Missing KWin package file: ${filename}`);
}
const manifest = JSON.parse(
  await readFile(join(root, "packages/kwin/package.json"), "utf8")
) as { version: string };
const metadata = JSON.parse(strFromU8(entry("metadata.json"))) as {
  KPlugin: { Version: string; Id: string };
  "X-Plasma-API": string;
  "X-Plasma-MainScript": string;
};
assert.equal(metadata.KPlugin.Version, manifest.version);
assert.equal(metadata["X-Plasma-API"], "declarativescript");
assert.equal(metadata["X-Plasma-MainScript"], "ui/main.qml");
assert(metadata.KPlugin.Id, "Plugin must have a stable ID");
const source = strFromU8(entry("contents/code/krohnkite.js"));
const assertLoweredGenerators = (node: unknown): void => {
  if (node === null || typeof node !== "object") {
    return;
  }
  if (Array.isArray(node)) {
    for (const item of node) {
      assertLoweredGenerators(item);
    }
    return;
  }
  assert.notEqual(
    Reflect.get(node, "generator"),
    true,
    "The Qt bundle must lower every native generator into a state machine"
  );
  assert.notEqual(
    Reflect.get(node, "type"),
    "YieldExpression",
    "The Qt bundle must not contain native yield expressions"
  );
  for (const value of Object.values(node)) {
    assertLoweredGenerators(value);
  }
};
assertLoweredGenerators(parse(source, { ecmaVersion: 2017 }));
assert.equal(
  strFromU8(entry("NOTICE")),
  await readFile(join(root, "NOTICE"), "utf8"),
  "The installable package must retain the distribution notice"
);
assert.equal(
  strFromU8(entry("licenses/Babel-helpers-LICENSE.txt")),
  await readFile(
    join(root, "packages/kwin/assets/licenses/Babel-helpers-LICENSE.txt"),
    "utf8"
  ),
  "The installable package must retain the complete Babel helpers license"
);
const sourceMapName = filenames.find((name) => name.endsWith(".js.map"));
assert(sourceMapName, "Release must include a bundle source map");
const sourceMap = JSON.parse(
  await readFile(join(dist, sourceMapName), "utf8")
) as { sources: string[] };
const testSourcePattern = /\.test\.[cm]?[jt]sx?$/u;
for (const filename of sourceMap.sources) {
  assert(
    !(filename.includes("vitest") || testSourcePattern.test(filename)),
    `Test dependencies must not reach the installed KWin script: ${filename}`
  );
}
assert(
  sourceMap.sources.some((filename) =>
    filename.includes("kwinscript-api/src/")
  ),
  "The installed script must consume the independent KWin API Effect package"
);
assert(
  !/\b(?:import|require)\s*\(/u.test(source),
  "KWin bundle must not need an external module loader"
);
const context: {
  Krohnkite?: { createRuntime?: unknown };
  globalThis: undefined;
  BigInt: undefined;
} = {
  BigInt: undefined,
  globalThis: undefined,
};
runInNewContext(
  `Object.fromEntries = undefined;
Object.hasOwn = undefined;
for (var name of ["at", "flatMap", "flat", "findLast", "findLastIndex", "toSorted", "toReversed", "toSpliced"]) {
  Object.defineProperty(Array.prototype, name, { value: undefined, configurable: true });
}
// QV4 exposes these native properties as readonly, and copies only string keys.
Object.defineProperty(Object, "assign", {
  writable: false,
  configurable: false,
  value: function(target) {
    for (var index = 1; index < arguments.length; index++) {
      var source = arguments[index];
      if (source === null || source === undefined) continue;
      for (var key of Object.keys(Object(source))) target[key] = source[key];
    }
    return target;
  }
});
Object.defineProperty(Object, "defineProperties", {
  writable: false,
  configurable: false,
  value: function(target, descriptors) {
    for (var key of Object.keys(descriptors)) Object.defineProperty(target, key, descriptors[key]);
    return target;
  }
});`,
  context
);
runInNewContext(source, context, { timeout: 10_000 });
assert.equal(
  typeof context.Krohnkite?.createRuntime,
  "function",
  "IIFE must expose its QML entry without Node globals"
);
assert(
  !("debugEffect" in (context.Krohnkite ?? {})),
  "Temporary Effect diagnostics must not be exported by release assets"
);
// Run the same synchronous host lifecycle as the real-Qt CI fixture. Keeping
// its host objects inside this VM prevents V8 Array methods leaking into QV4 tests.
const qtFixture = await readFile(join(root, "tests/qml/runtime.qml"), "utf8");
const fixtureStart = qtFixture.indexOf("    function assertTrue(");
const fixtureEnd = qtFixture.indexOf("    Timer {", fixtureStart);
assert(
  fixtureStart >= 0 && fixtureEnd > fixtureStart,
  "Qt lifecycle fixture must retain its JavaScript functions"
);
runInNewContext(
  `var runtime = null;
var K = { Krohnkite: Krohnkite };
${qtFixture.slice(fixtureStart, fixtureEnd)}
testRuntime();`,
  context,
  { timeout: 10_000 }
);
const qml = strFromU8(entry("contents/ui/main.qml"));
assert(
  qml.includes("../code/krohnkite.js"),
  "QML entry must import the packaged bundle"
);
const shortcutHandlers = [
  ...strFromU8(entry("contents/ui/shortcuts.qml")).matchAll(
    /ShortcutHandler\s*\{([^}]+)\}/gu
  ),
];
assert.equal(shortcutHandlers.length, 39, "Retain all 39 shortcut handlers");
const shortcutActions = new Set<string>();
const defaultShortcuts: string[] = [];
for (const [, handler] of shortcutHandlers) {
  const action = handler?.match(/\bname:\s*"([^"]+)";/u)?.[1];
  const sequence = handler?.match(/\bsequence:\s*"([^"]*)";/u)?.[1];
  assert(action, "Every shortcut handler must declare its action name");
  assert.notEqual(sequence, undefined, `Missing default sequence: ${action}`);
  shortcutActions.add(action);
  if (sequence) {
    assert(
      /^Meta\+[^+]+$/u.test(sequence) &&
        !/\b(?:Alt|Control|Ctrl|Shift)\b/u.test(sequence),
      `Default shortcuts must use only Meta plus one key: ${action}`
    );
    defaultShortcuts.push(sequence);
  }
}
assert.equal(shortcutActions.size, 39, "Shortcut action names must be unique");
assert.equal(
  defaultShortcuts.length,
  25,
  "Retain 25 default shortcut bindings"
);
assert.equal(
  new Set(defaultShortcuts).size,
  defaultShortcuts.length,
  "Default shortcuts must not share a key sequence"
);
const sourceName = filenames.find((name) => name.endsWith(".source.zip"));
assert(sourceName, "Release must include complete source");
const sources = unzipSync(await readFile(join(dist, sourceName)));
for (const filename of [
  "pnpm-lock.yaml",
  "README.md",
  "NOTICE",
  "packages/kwin/assets/licenses/Babel-helpers-LICENSE.txt",
  "vitest.config.ts",
  "RUNTIME.md",
  "CONFIGURATION.md",
  "RESOURCE-MIGRATION.md",
  "docs/images/screenshot.png",
  "docs/images/conf.png",
  "flake.nix",
  "flake.lock",
  "NIX.md",
  "nix/package.nix",
  "nix/toolchain.nix",
  "nix/qt-check.nix",
  "packages/config/examples/kwinrc",
  "scripts/kwin-config-smoke.sh",
  "tests/qml/file-configuration.qml",
  "packages/kwinscript-api/src/index.ts",
  ".gitmodules",
  "upstream-sources.sha256.json",
  ".repo/effect/packages/effect/src/Effect.ts",
  ".repo/krohnkite/README.md",
]) {
  assert(sources[filename], `Missing offline source file: ${filename}`);
}
const sums = (await readFile(join(dist, "SHA256SUMS"), "utf8"))
  .trim()
  .split("\n");
for (const line of sums) {
  const [expected, filename] = line.split("  ");
  assert(filename, "Invalid checksum line");
  const actual = createHash("sha256")
    .update(await readFile(join(dist, filename)))
    .digest("hex");
  assert.equal(actual, expected, `Checksum mismatch: ${filename}`);
}
console.log(
  `Verified ${scripts[0]}: lowered generators, licenses, QML entry, 39 unique actions with 25 Meta-only defaults, masked Qt lifecycle, complete source, and checksums`
);
