import { resolve } from "node:path";
import { defineConfig } from "vitest/config";

const root = import.meta.dirname;

export default defineConfig({
  resolve: { dedupe: ["effect", "vitest"] },
  root,
  test: {
    environment: "node",
    globals: false,
    projects: ["config", "core", "kwinscript-api", "runtime", "kwin"].map(
      (name) => ({
        root: resolve(root, "packages", name),
        test: {
          include: ["src/**/*.test.ts", "tooling/**/*.test.ts"],
          name: `@krohnkite/${name}`,
        },
      })
    ),
    restoreMocks: true,
  },
});
