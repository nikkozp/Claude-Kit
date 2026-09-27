# Review policy (read by review agents)

## Flag
- Correctness bugs, broken requirements from spec.md
- Security: authz, injection, secrets, unsafe deserialization
- Data safety: migrations, money arithmetic, idempotency
- Missing tests for new behavior

## Do not flag
- Formatting and style (the formatter and analyzers own this)
- Hypothetical edge cases that the spec rules out
- Extra abstractions "for the future"

## Output
Table: | Severity (High/Medium/Low) | File:line | Issue | Suggested fix |.
Only issues that affect correctness or stated requirements. If none: "No findings".
