import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { isAbsolute, join, relative, resolve } from "node:path";
import { unzipSync } from "fflate";

const root = resolve(import.meta.dirname, "..");
const manifest = JSON.parse(
  await readFile(join(root, "packages/kwin/package.json"), "utf8")
) as { version: string };
const base = `krohnkite-${manifest.version}`;
const source = unzipSync(
  await readFile(join(root, "dist", `${base}.source.zip`))
);
const script = unzipSync(
  await readFile(join(root, "dist", `${base}.kwinscript`))
);
const stage = join(root, ".workcache/offline-source");
assert.equal(relative(root, stage), join(".workcache", "offline-source"));
await rm(stage, { force: true, recursive: true });
for (const [filename, content] of Object.entries(source)) {
  const destination = resolve(stage, filename);
  const within = relative(stage, destination);
  assert(
    !(within.startsWith("..") || isAbsolute(within)),
    `Unsafe source path: ${filename}`
  );
  await mkdir(resolve(destination, ".."), { recursive: true });
  await writeFile(destination, content);
}
const bundle = script["contents/code/krohnkite.js"];
assert(bundle, "Package must include its JavaScript bundle");
await mkdir(join(stage, "packages/kwin/dist"), { recursive: true });
await writeFile(join(stage, "packages/kwin/dist/krohnkite.js"), bundle);
await cp(
  join(root, "dist", `${base}.js.map`),
  join(stage, "packages/kwin/dist/krohnkite.js.map")
);
const runPackage = () =>
  execFileSync(
    process.execPath,
    [
      join(root, "node_modules/tsx/dist/cli.mjs"),
      join(stage, "scripts/package.ts"),
    ],
    {
      cwd: stage,
      encoding: "utf8",
      stdio: "pipe",
    }
  );
runPackage();
const hash = async (filename: string) =>
  createHash("sha256")
    .update(await readFile(filename))
    .digest("hex");
assert.equal(
  await hash(join(stage, "dist", `${base}.kwinscript`)),
  await hash(join(root, "dist", `${base}.kwinscript`)),
  "Offline repack must preserve the installable artifact bytes"
);

const license = join(stage, ".repo/effect/LICENSE");
const original = await readFile(license);
await writeFile(license, "tampered source\n");
assert.throws(
  runPackage,
  /Offline upstream checksum mismatch/u,
  "Repack must reject a modified pinned source file"
);
await writeFile(license, original);
const extra = join(stage, ".repo/effect/unexpected-offline-file");
await writeFile(extra, "unexpected source\n");
assert.throws(
  runPackage,
  /upstream file was added or removed/u,
  "Repack must reject files outside its source inventory"
);
await rm(extra);
console.log(
  "Verified offline source repack: identical .kwinscript bytes, tamper detection, and exact source inventory"
);
