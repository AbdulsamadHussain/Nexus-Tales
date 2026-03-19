# Flutter Shell

Phase 0 provides a hand-authored Flutter shell because the Flutter SDK is not installed in this workspace.

Canonical contracts are not duplicated in Dart. The source of truth is:

- `packages/contracts/src/index.ts`
- `packages/contracts/generated/openapi.json`

Once Flutter tooling is installed, Dart models and API clients should be generated from the OpenAPI artifact instead of being hand-written.

