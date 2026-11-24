---
"@krohnkite/kwinscript-api": minor
"@krohnkite/kwin": minor
---

Extract the reusable KWin API Effect service with typed failures and scoped
signals, timers, and callback cancellation. The KWin tiler consumes the service
while keeping the compositor runtime independent of Qt.

Migrate workspace behavior tests to Vitest 5 and @effect/vitest 4, preserve the
upstream layout fixtures, and document the Qt host constraints on Effect.
