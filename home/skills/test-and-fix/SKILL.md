---
name: test-and-fix
description: Run the test suite and fix failing tests at the root cause. Invoke only when the user or another skill explicitly asks for it.
arguments: [filter]
---
1. Run `dotnet test --nologo -v q`, adding `--filter "$filter"` if a filter was given.
2. For each failure find the root cause in production code. Change a test only if the test
   itself is wrong, and say so explicitly.
3. Re-run. At most 3 iterations; then stop and report what is still red and why.
Never skip, ignore or delete tests to get green.
End with a table: Test | Cause | Fix | Status.
