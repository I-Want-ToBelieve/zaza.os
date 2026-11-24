import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { defineConfig } from "tsdown";
import { effectQtPlugin, qtBanner } from "./packages/kwin/tooling/effect-qt.ts";

const manifest = JSON.parse(readFileSync(resolve("package.json"), "utf8")) as {
  name: string;
};
const kwin = manifest.name === "@krohnkite/kwin";

export default defineConfig({
  clean: true,
  deps: kwin ? { alwaysBundle: [/^@krohnkite\//, /^effect(?:\/|$)/] } : {},
  dts: false,
  entry: [resolve("src/index.ts")],
  format: kwin ? "iife" : "esm",
  outDir: resolve("dist"),
  outputOptions: kwin
    ? {
        banner: qtBanner,
        codeSplitting: false,
        entryFileNames: "krohnkite.js",
        name: "Krohnkite",
      }
    : { entryFileNames: "[name].js" },
  platform: "neutral",
  plugins: kwin ? [effectQtPlugin()] : [],
  sourcemap: true,
  target: "es2017",
  tsconfig: resolve("tsconfig.json"),
});
