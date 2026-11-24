# Repository conventions

Read the root README before changing runtime behavior. `.repo/` contains pinned
upstream Git submodules for reference; do not edit vendored files. Update a gitlink
and upstreams.json together when intentionally upgrading an upstream source.

Use pnpm 11.22.0 and Node 24. TypeScript 7.0.2 is the native compiler. Both
`@typescript/native` and `typescript` use the named `typescript` pnpm catalog;
the first name is an npm alias to the published TypeScript package. Keep the
requested Ultracite 7.9.4 and @effect/tsgo 0.43.0 pins unless an upgrade is asked for.

The core must remain independent of KWin and Node. Normalize configuration at the
config boundary. Use Effect v4 services and typed failures for runtime I/O, and
plain functions for geometry. Connect KWin callbacks through scoped cleanup and
guard against geometry-change events caused by applying the current plan.
Keep reusable Qt boundary types, typed errors, and scoped resources in
`@krohnkite/kwinscript-api`, independent of the tiler packages. The KWin adapter
maps platform errors into the generic compositor boundary.

QML is an ECMAScript 2016 host with selected newer syntax. Do not assume browser
or Node globals, BigInt, globalThis, Object.fromEntries, or Object.hasOwn. Keep any
compatibility handling in the application bundle; verify it with an actual Qt
engine as well as the isolated JavaScript sandbox. No Node imports may reach the
installed script.

Run `pnpm check` and `pnpm release:assets` before declaring a release ready. Keep
tests about observable behavior: layouts, surface isolation, filtering, shortcut
actions, configuration reload, callback cleanup, bundle loading, and package
contents. Changesets records package version changes; GitHub release assets use
the KWin package version. Never publish a release with a mismatched tag/version.

Use Vitest 5 and @effect/vitest 4. Effect programs use `it.effect`, which already
provides Scope in v4; pure functions and the synchronous Qt entry point use plain
`it`. Do not use node:test, or escape Effect test services with runPromise. Test
dependencies must remain outside the installed bundle. Verify runtime changes
with actual Qt and KWin after the Node-based tests pass.
