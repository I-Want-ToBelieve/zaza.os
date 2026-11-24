{
  lib,
  stdenv,
  pkgs,
  fetchPnpmDeps,
  pnpmConfigHook,
  autoPatchelfHook,
  jq,
  zip,
  source,
}: let
  toolchain = import ./toolchain.nix {inherit pkgs;};
  inherit (toolchain) nodejs pnpm;
  # Relative flake inputs can expose /./ in outPath, while filter callbacks
  # receive normalized paths. Normalize both against a fresh source root.
  sourceRoot = "/" + lib.concatStringsSep "/" (lib.path.subpath.components (lib.removePrefix "/" (toString source)));
  manifest = builtins.fromJSON (builtins.readFile (sourceRoot + "/packages/kwin/package.json"));
  rootFiles = [
    "package.json"
    "pnpm-lock.yaml"
    "pnpm-workspace.yaml"
    "nx.json"
    "tsconfig.base.json"
    "tsconfig.json"
    "tsdown.config.ts"
    "vitest.config.ts"
    "biome.jsonc"
    "taze.config.ts"
    "upstreams.json"
    "LICENSE"
    "NOTICE"
    ".gitignore"
  ];
  src = builtins.path {
    path = sourceRoot;
    name = "krohnkite-source";
    filter = path: _type: let
      relative = lib.removePrefix (toString sourceRoot + "/") (toString path);
      parts = lib.splitString "/" relative;
      ignored = [".git" ".repo" ".workcache" ".pnpm-store" ".nx" "node_modules" "dist" "coverage" "result"];
    in
      toString path
      == toString sourceRoot
      || (!(lib.any (part: builtins.elem part ignored) parts)
        && (builtins.elem relative rootFiles
          || builtins.elem (builtins.head parts) ["packages" "scripts" "tests"]));
  };
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "krohnkite-effect";
    inherit (manifest) version;
    inherit src;

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      inherit pnpm;
      fetcherVersion = 4;
      hash = "sha256-nJozsydt3be6TBT3bUkjc9VZRagGbBHvg4Rv/CZW4nY=";
      env = {
        pnpm_config_fetch_timeout = "600000";
        pnpm_config_network_concurrency = "4";
        pnpm_config_fetch_retries = "4";
      };
      # pnpm may report success after omitting an optional package whose download
      # timed out. The fetcher installs with --force, so all platform packages
      # must resolve before its store is normalized, archived, and hashed.
      postInstall = ''
        node <<'NODE'
        const assert = require("node:assert/strict");
        const { readFileSync } = require("node:fs");
        const { createRequire } = require("node:module");
        const metadata = (resolver, name) => {
          let filename;
          try {
            filename = resolver.resolve(name + "/package.json");
          } catch (cause) {
            throw new Error("Incomplete pnpm dependency cache: missing " + name, { cause });
          }
          const value = JSON.parse(readFileSync(filename, "utf8"));
          assert.equal(value.name, name, "Native package metadata must match its requested name");
          return { value, resolver: createRequire(filename) };
        };
        let verified = 0;
        const native = (owner, name, platform, cpu) => {
          const dependency = metadata(owner.resolver, name).value;
          assert.equal(dependency.version, owner.value.version, "Native package version mismatch: " + name);
          assert(dependency.os?.includes(platform), "Native package OS mismatch: " + name);
          assert(dependency.cpu?.includes(cpu), "Native package CPU mismatch: " + name);
          verified += 1;
        };
        const effect = metadata(require, "@effect/tsgo");
        for (const [platform, cpu] of [
          ["darwin", "arm64"], ["darwin", "x64"],
          ["linux", "arm"], ["linux", "arm64"], ["linux", "x64"],
          ["win32", "arm64"], ["win32", "x64"],
        ]) {
          native(effect, "@effect/tsgo-" + platform + "-" + cpu, platform, cpu);
        }
        const typescript = metadata(require, "typescript");
        const rolldown = metadata(metadata(require, "tsdown").resolver, "rolldown");
        const biome = metadata(require, "@biomejs/biome");
        const nx = metadata(require, "nx");
        const esbuild = metadata(metadata(require, "tsx").resolver, "esbuild");
        for (const cpu of ["x64", "arm64"]) {
          native(typescript, "@typescript/typescript-linux-" + cpu, "linux", cpu);
          native(rolldown, "@rolldown/binding-linux-" + cpu + "-gnu", "linux", cpu);
          native(biome, "@biomejs/cli-linux-" + cpu, "linux", cpu);
          native(nx, "@nx/nx-linux-" + cpu + "-gnu", "linux", cpu);
          native(esbuild, "@esbuild/linux-" + cpu, "linux", cpu);
        }
        console.log("Verified " + verified + " required native package manifests before pnpm cache hashing");
        NODE
      '';
    };

    nativeBuildInputs = [nodejs pnpm pnpmConfigHook autoPatchelfHook jq zip];
    buildInputs = [stdenv.cc.cc.lib];
    strictDeps = true;
    NX_DAEMON = "false";
    NX_ISOLATE_PLUGINS = "false";
    NX_SKIP_NX_CACHE = "true";

    preBuild = ''
      # Install is offline and skips lifecycle scripts. Patch from the packaged
      # Linux Effect-tsgo artifact before adapting native executables to NixOS.
      pnpm exec effect-tsgo patch
      autoPatchelf node_modules
      test "$(pnpm --version)" = 11.22.0
      pnpm exec tsc --version
      node --input-type=module -e 'import assert from "node:assert/strict"; import { createRequire } from "node:module"; const require = createRequire(import.meta.url); assert.equal(require("typescript/package.json").version, "7.0.2"); assert.equal(require("@effect/tsgo/package.json").version, "0.43.0");'
    '';

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    doCheck = true;
    checkPhase = ''
      runHook preCheck
      pnpm typecheck
      pnpm test:all
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      package="$out/share/kwin/scripts/krohnkite"
      mkdir -p "$package/contents/code" "$package/licenses" "$out/share/krohnkite"
      cp -R packages/kwin/assets/. "$package/"
      jq --arg version "$version" '.KPlugin.Version = $version' packages/kwin/assets/metadata.json > "$package/metadata.json"
      cp packages/kwin/dist/krohnkite.js "$package/contents/code/krohnkite.js"
      cp LICENSE "$package/LICENSE"
      cp NOTICE "$package/NOTICE"
      cp LICENSE "$package/licenses/Krohnkite-LICENSE.txt"
      cp node_modules/effect/LICENSE "$package/licenses/Effect-LICENSE.txt"
      cp upstreams.json "$package/upstreams.json"
      cp packages/kwin/dist/krohnkite.js.map "$out/share/krohnkite/krohnkite.js.map"
      (
        cd "$package"
        export TZ=UTC
        find . -type f -exec touch -t 198001010000 {} +
        find . -type f -print | LC_ALL=C sort | zip -qX "$out/share/krohnkite/krohnkite-$version.kwinscript" -@
      )
      runHook postInstall
    '';

    passthru = {inherit pnpm nodejs;};
    meta = {
      description = "KWin tiling rewritten as independent Effect v4 packages";
      homepage = "https://codeberg.org/anametologin/Krohnkite";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
    };
  })
