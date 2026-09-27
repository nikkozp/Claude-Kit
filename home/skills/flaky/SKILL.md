---
name: flaky
description: Hunt a flaky test - run it repeatedly, find the nondeterminism, fix it.
disable-model-invocation: true
arguments: [filter, runs]
---
1. Run `dotnet test --nologo -v q --filter "$filter"` $runs times (10 if not given) and count failures.
2. Zero failures -> report "not reproduced in N runs" and stop.
3. Look for nondeterminism: DateTime.Now and time zones, Task.Delay and races, shared static
   state, test order, random data, culture, real network or file system calls.
4. Fix the cause (inject TimeProvider, isolate state, await properly). Re-run the same number
   of times; success means zero failures.
5. If a proper fix is not possible now: mark the test `[Trait("Category", "Flaky")]` and explain why.
Never add retries or longer sleeps as the fix.
End with: runs before | failures before | cause | fix | failures after.
