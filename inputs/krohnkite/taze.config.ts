import { defineConfig } from "taze";

export default defineConfig({
  exclude: ["@effect/tsgo", "@typescript/native", "typescript", "ultracite"],
  recursive: true,
});
