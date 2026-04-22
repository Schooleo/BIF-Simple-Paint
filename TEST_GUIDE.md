# Flutter Test Guide

This guide defines the rules contributors should follow when adding or updating tests in this project.

## Scope

- Add tests for all new business logic and bug fixes.
- Prefer unit tests for providers, repositories, and utility functions.
- Add widget tests only for critical UI flows and integration between UI and state.

## Core Rules

1. Keep tests deterministic.
- Do not depend on real network, file system state, or system time.
- Use fakes/mocks and controlled test data.

2. Use clear test naming.
- Format: `method_or_behavior_condition_expectedResult`.
- Example: `saveCanvas_withValidStrokes_returnsTrue`.

3. Follow Arrange-Act-Assert.
- Arrange: setup inputs and dependencies.
- Act: execute the unit under test.
- Assert: verify output and side effects.

4. One behavior per test.
- A single test should validate one behavior only.
- If multiple assertions are needed, they should describe the same behavior.

5. Test happy paths and failure paths.
- Include invalid inputs, empty states, and repository/service failures.

6. Keep tests fast.
- Unit tests should run in milliseconds.
- Avoid unnecessary widget pumping or long async waits.

## Flutter + Riverpod Rules

- Use `ProviderContainer` for provider-level unit tests.
- Override providers for mocks using `overrides`.
- Dispose `ProviderContainer` in teardown.
- Avoid relying on global provider state between tests.

## Widget Test Rules

- Use `testWidgets` only when UI behavior needs validation.
- Pump the smallest widget tree needed.
- Use stable finders (`byType`, `byKey`, explicit text) to avoid flaky tests.
- Always call `pump`/`pumpAndSettle` intentionally and only when needed.

## File and Structure Conventions

- Place tests under `test/` mirroring `lib/` structure.
- Name files as `<feature>_test.dart`.
- Group related tests with `group()` and short behavior-focused descriptions.

## Mocking and Test Data

- Prefer lightweight fake implementations over heavy mocking.
- Keep shared builders/factories in `test/core/` when reused.
- Avoid hard-coded magic values; use named constants in test files.

## Minimum Quality Checks Before PR

- Run:

```bash
flutter analyze
flutter test
```

- For bug fixes, include at least one regression test that fails before the fix and passes after it.
- Do not merge PRs with skipped tests unless the reason is documented in the PR description.
