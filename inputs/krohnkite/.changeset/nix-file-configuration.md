---
"@krohnkite/kwin": patch
"@krohnkite/config": patch
"@krohnkite/runtime": patch
"@krohnkite/kwinscript-api": minor
---

Add a reproducible Nix flake and source package for Plasma integration. Document
native kwinrc file configuration and verify configuration reloads. Preserve
upstream QML resources and include the original documentation images and resource
mapping in source releases.

Use explicit synchronous Effect contexts for Qt callbacks and lifecycle cleanup,
retain rejection of genuinely asynchronous programs, and refresh window visibility
when KWin emits hiddenChanged.

Lower native generators only in the KWin bundle to avoid the reproduced Qt QV4
crash under multi-window and garbage-collection pressure, preserving Effect
iteration, error and scope semantics and composed source maps.
