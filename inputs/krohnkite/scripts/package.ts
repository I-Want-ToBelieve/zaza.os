import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  cp,
  mkdir,
  readdir,
  readFile,
  rm,
  stat,
  writeFile,
} from "node:fs/promises";
import { basename, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { strToU8, zipSync } from "fflate";

type FileMap = Record<string, Uint8Array>;
interface Upstream {
  branch: string;
  path: string;
  revision: string;
  url: string;
  version?: string;
}
interface SourceInventory {
  readonly files: Record<string, string>;
  readonly upstreams: Record<string, Upstream>;
}

const root = resolve(import.meta.dirname, "..");
const dist = join(root, "dist");
const app = join(root, "packages/kwin");
const manifest = JSON.parse(
  await readFile(join(app, "package.json"), "utf8")
) as {
  version: string;
};
const { version } = manifest;
const tag = process.env.RELEASE_TAG;
if (tag && tag !== `v${version}` && tag !== `@krohnkite/kwin@${version}`) {
  throw new Error(
    `Release tag ${tag} does not match KWin package version ${version}`
  );
}

const ignored = new Set([
  ".git",
  ".nx",
  ".pnpm-store",
  ".workcache",
  "node_modules",
  "dist",
  "coverage",
]);
const filesIn = async (directory: string, prefix = ""): Promise<FileMap> => {
  const result: FileMap = {};
  const entries = await readdir(directory, { withFileTypes: true });
  entries.sort((left, right) => left.name.localeCompare(right.name, "en"));
  for (const entry of entries) {
    if (ignored.has(entry.name) || entry.name.endsWith(".tsbuildinfo")) {
      continue;
    }
    const filename = join(directory, entry.name);
    const archivePath = `${prefix}${entry.name}`;
    if (entry.isDirectory()) {
      Object.assign(result, await filesIn(filename, `${archivePath}/`));
    } else if (entry.isFile()) {
      result[archivePath] = await readFile(filename);
    }
  }
  return result;
};

const upstreams = JSON.parse(
  await readFile(join(root, "upstreams.json"), "utf8")
) as Record<string, Upstream>;
const upstreamFiles: FileMap = {};
let gitMetadataMissing = false;
for (const [name, upstream] of Object.entries(upstreams)) {
  const checkout = join(root, upstream.path);
  Object.assign(upstreamFiles, await filesIn(checkout, `${upstream.path}/`));
  const gitMetadata = await stat(join(checkout, ".git")).catch(() => undefined);
  if (gitMetadata === undefined) {
    gitMetadataMissing = true;
    continue;
  }
  const revision = execFileSync(
    "git",
    [
      "-c",
      `safe.directory=${checkout.split(sep).join("/")}`,
      "-C",
      checkout,
      "rev-parse",
      "HEAD",
    ],
    { encoding: "utf8" }
  ).trim();
  if (revision !== upstream.revision) {
    throw new Error(
      `${name} submodule is ${revision}; update upstreams.json when changing the pinned revision`
    );
  }
  const changes = execFileSync(
    "git",
    [
      "-c",
      `safe.directory=${checkout.split(sep).join("/")}`,
      "-C",
      checkout,
      "status",
      "--porcelain",
      "--untracked-files=normal",
    ],
    { encoding: "utf8" }
  ).trim();
  if (changes.length > 0) {
    throw new Error(
      `${name} submodule has local changes; release assets require the pinned clean sources`
    );
  }
}
const upstreamHashes: Record<string, string> = {};
for (const [filename, content] of Object.entries(upstreamFiles)) {
  upstreamHashes[filename] = createHash("sha256").update(content).digest("hex");
}
if (gitMetadataMissing) {
  const inventory = JSON.parse(
    await readFile(join(root, "upstream-sources.sha256.json"), "utf8")
  ) as SourceInventory;
  if (JSON.stringify(inventory.upstreams) !== JSON.stringify(upstreams)) {
    throw new Error(
      "Offline source inventory does not match the pinned upstream metadata"
    );
  }
  const actualPaths = Object.keys(upstreamHashes).sort((left, right) =>
    left.localeCompare(right, "en")
  );
  const expectedPaths = Object.keys(inventory.files).sort((left, right) =>
    left.localeCompare(right, "en")
  );
  if (JSON.stringify(actualPaths) !== JSON.stringify(expectedPaths)) {
    throw new Error(
      "Offline source inventory differs: an upstream file was added or removed"
    );
  }
  for (const filename of actualPaths) {
    if (upstreamHashes[filename] !== inventory.files[filename]) {
      throw new Error(`Offline upstream checksum mismatch: ${filename}`);
    }
  }
}

const metadata = JSON.parse(
  await readFile(join(app, "assets/metadata.json"), "utf8")
) as {
  KPlugin: { Version?: string; Id?: string };
};
metadata.KPlugin.Version = version;
const packageFiles = await filesIn(join(app, "assets"));
packageFiles["metadata.json"] = strToU8(
  `${JSON.stringify(metadata, null, 2)}\n`
);
const bundle = await readFile(join(app, "dist/krohnkite.js"));
packageFiles["contents/code/krohnkite.js"] = bundle;
packageFiles.LICENSE = await readFile(join(root, "LICENSE"));
packageFiles.NOTICE = await readFile(join(root, "NOTICE"));

const sourceFiles = await filesIn(root);
Object.assign(sourceFiles, upstreamFiles);
sourceFiles["upstream-sources.sha256.json"] = strToU8(
  `${JSON.stringify({ files: upstreamHashes, upstreams }, null, 2)}\n`
);

const generatorPackages = [
  "@babel/core",
  "@babel/helpers",
  "@babel/plugin-transform-block-scoping",
  "@babel/plugin-transform-destructuring",
  "@babel/plugin-transform-for-of",
  "@babel/plugin-transform-regenerator",
] as const;
const generatorVersions: Record<string, string> = {};
for (const name of generatorPackages) {
  const installed = JSON.parse(
    await readFile(
      fileURLToPath(import.meta.resolve(`${name}/package.json`)),
      "utf8"
    )
  ) as { version: string };
  generatorVersions[name] = installed.version;
}
const helperLicense = await readFile(
  join(
    fileURLToPath(import.meta.resolve("@babel/helpers/package.json")),
    "../LICENSE"
  )
);
const packagedHelperLicense = await readFile(
  join(app, "assets/licenses/Babel-helpers-LICENSE.txt")
);
if (!helperLicense.equals(packagedHelperLicense)) {
  throw new Error(
    "The checked-in Babel helpers license must match the installed build dependency"
  );
}
if (generatorVersions["@babel/helpers"] !== "8.0.5") {
  throw new Error("Update NOTICE when upgrading the Babel helpers dependency");
}

const provenance = {
  compiler: "typescript@7.0.2 with @effect/tsgo@0.43.0",
  effectRuntime: "4.0.0",
  format: "KWin/Script",
  name: "Krohnkite",
  pluginId: metadata.KPlugin.Id,
  qtGeneratorTransform: {
    packages: generatorVersions,
    strategy: "babel-regenerator",
  },
  upstreams,
  version,
};
const provenanceBytes = strToU8(`${JSON.stringify(provenance, null, 2)}\n`);
packageFiles["upstreams.json"] = provenanceBytes;
packageFiles["licenses/Effect-LICENSE.txt"] = await readFile(
  join(root, ".repo/effect/LICENSE")
);
packageFiles["licenses/Krohnkite-LICENSE.txt"] = await readFile(
  join(root, ".repo/krohnkite/LICENSE")
);

await mkdir(dist, { recursive: true });
for (const filename of await readdir(dist)) {
  if (filename.startsWith("krohnkite-") || filename === "SHA256SUMS") {
    if (basename(filename) !== filename) {
      throw new Error(`Invalid generated artifact filename: ${filename}`);
    }
    await rm(join(dist, filename), { force: true });
  }
}
// Only the task's own generated output directory is recreated.
const stage = join(dist, "kwinscript");
const stageRelative = relative(root, resolve(stage));
if (
  stageRelative !== join("dist", "kwinscript") ||
  stageRelative.startsWith("..")
) {
  throw new Error(
    `Refusing to recreate a package stage outside this workspace: ${stage}`
  );
}
await rm(stage, { force: true, recursive: true });
await mkdir(stage, { recursive: true });
for (const [filename, content] of Object.entries(packageFiles)) {
  const destination = join(stage, filename);
  await mkdir(resolve(destination, ".."), { recursive: true });
  await writeFile(destination, content);
}

const epoch = new Date(
  Number(process.env.SOURCE_DATE_EPOCH ?? "315532800") * 1000
);
if (
  !Number.isFinite(epoch.getTime()) ||
  epoch.getUTCFullYear() < 1980 ||
  epoch.getUTCFullYear() > 2099
) {
  throw new Error(
    "SOURCE_DATE_EPOCH must be a valid ZIP timestamp between 1980 and 2099"
  );
}
// ZIP uses local calendar fields; normalize UTC fields to make bytes independent of the runner timezone.
const stamp = new Date(
  epoch.getUTCFullYear(),
  epoch.getUTCMonth(),
  epoch.getUTCDate(),
  epoch.getUTCHours(),
  epoch.getUTCMinutes(),
  epoch.getUTCSeconds()
);
const zipOptions = { level: 9 as const, mtime: stamp };
const base = `krohnkite-${version}`;
const assets = [
  `${base}.kwinscript`,
  `${base}.source.zip`,
  `${base}.js`,
  `${base}.js.map`,
  `${base}.provenance.json`,
];
await writeFile(join(dist, assets[0] ?? ""), zipSync(packageFiles, zipOptions));
await writeFile(join(dist, assets[1] ?? ""), zipSync(sourceFiles, zipOptions));
await writeFile(join(dist, assets[2] ?? ""), bundle);
await cp(join(app, "dist/krohnkite.js.map"), join(dist, assets[3] ?? ""));
await writeFile(join(dist, assets[4] ?? ""), provenanceBytes);
const checksums: string[] = [];
for (const filename of assets) {
  const digest = createHash("sha256")
    .update(await readFile(join(dist, filename)))
    .digest("hex");
  checksums.push(`${digest}  ${filename}`);
}
await writeFile(join(dist, "SHA256SUMS"), `${checksums.join("\n")}\n`);
console.log(`Built ${relative(root, dist)}: ${assets.join(", ")}, SHA256SUMS`);
