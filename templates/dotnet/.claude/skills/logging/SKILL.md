---
name: logging
description: Structured logging standard (Serilog, CLEF, scopes/correlation, redaction). Use when adding or reviewing ILogger calls, log scopes, or logging configuration.
---

# Logging Rules — Structured Logging Standard

Every log event must be machine-parseable in any observability UI (Seq, Datadog, Application
Insights) without string-scraping: consistent field names, one JSON event per line in
production, exceptions passed as real exception objects, and no secrets.

## 1. Structured Templates — Never String Interpolation
- Always use named placeholders: `_logger.LogInformation("Cancel #{OrderId} for {Sku}", orderId, sku);`
- **Never** `$"..."` or string concatenation in a log call — it destroys the property bag and
  makes the message untemplatable across every event of that type.
- **Exceptions are always the first argument**, never interpolated into the message:
  `_logger.LogError(ex, "Failed to process response with status code {StatusCode}", statusCode);`
  — never `_logger.LogError(ex.Message)` (this throws away the stack trace).

## 2. No `[Prefix]` Channels — Use Scopes Instead
Do not encode a channel/category into the message text (`"[Orders] Cancelling #{OrderId}"`). A
string prefix cannot be filtered/aggregated in Seq or Datadog the way a real property can. Push
it as a structured property via a scope instead, then keep the message itself prefix-free:

```csharp
using IDisposable? scope = _logger.BeginScope(new Dictionary<string, object>
{
    ["Category"] = "Orders"
});
_logger.LogInformation("Cancelling #{OrderId}", orderId);
```

- Reuse canonical property names across the system so cross-service queries in Seq/Datadog line
  up: `CorrelationId, UserId, Username, Category, EventType`, plus domain-specific ids
  (`OrderId`, `TenantId`, ...).
- A zero-dependency library must use the framework-agnostic `Microsoft.Extensions.Logging.ILogger.BeginScope`
  rather than a provider-specific scope helper, so it stays free of infrastructure references.

## 3. Correlation
- Every request/command handler should get a `CorrelationId` (`Guid`) and `RequestName` pushed
  via a pipeline behavior, so every log line emitted while handling a request stays
  correlatable even if the request itself doesn't log a lifecycle line.
- Log `Started {RequestName}` / `Completed {RequestName} in {ElapsedMs}ms` for commands (state
  changes), not for queries — queries run far more often and rarely carry decision-worthy
  information at start/end. Don't add a second, manual lifecycle pair around a handler that a
  pipeline behavior already covers.
- Push `UserId`/`Username` from the current-user context into the same scope; fall back to a
  literal `"anonymous"` when unauthenticated or when the request has no user context.

## 4. Standard Enriched Fields
Every log event should automatically carry: `Application, Environment, Version, MachineName,
ThreadId, TraceId, SpanId`. Set `Application` per-service in `appsettings.json` under
`Serilog:Properties:Application` — never hardcode it in C#. Don't manually re-add any of these
fields as a log-call argument.

## 5. Output Format — CLEF-JSON in Production, Text in Development
- **Production**: the Console sink uses `Serilog.Formatting.Compact.CompactJsonFormatter` — one
  CLEF JSON object per line, parsed natively by Seq/Datadog/App Insights from stdout.
- **Development**: the Console sink keeps a human-readable `outputTemplate` — don't switch this
  to JSON, it's what a developer reads directly in the terminal.
- Never change this per-environment split without re-verifying both a local dev run and a
  Production-configured run.

## 6. Secret Redaction
- **Secrets, API keys, and tokens are never logged — not even masked, not even at `Debug`.**
  Do not pass a secret value as a log argument in any form (plain, masked, truncated).
- A dedicated HTTP logging handler should redact a fixed set of sensitive headers
  (`Authorization`, `Api-Key`, `Api-Secret`, `Signature`, `Cookie`, `Set-Cookie`, and any
  provider-specific auth header) to `***REDACTED***` before logging request/response traffic —
  extend that set rather than logging headers manually elsewhere.
- Request/response bodies are logged at `Debug` only, truncated to a bounded length (e.g. 500
  chars). Don't raise that limit or log full bodies at `Information`+.
- If a signed request ever puts a signature in the **query string** (not a header), that URL
  must not reach a debug log unscrubbed — scrub the `signature=`/token query parameter before
  logging.
- Sink credentials (e.g. a Seq API key) never go into a committed `appsettings*.json` — use
  `dotnet user-secrets` locally and pipeline variable groups / env vars in production.

## 7. Log Levels
- `Trace`/`Debug` — verbose diagnostics (HTTP request/response bodies, retry attempts). Not
  enabled in Production by default.
- `Information` — normal business events worth keeping (order placed, request completed,
  connection established).
- `Warning` — recoverable/expected failure (transient HTTP error before retry, missing optional
  config).
- `Error` — unexpected failure that was caught; always pass the exception as the first argument.
- `Fatal` — reserved for unrecoverable startup failures.

## Anti-Patterns
- `$"..."` or string concatenation in any log call.
- `_logger.LogError(ex.Message)` instead of `_logger.LogError(ex, "template", args)`.
- A `[Prefix]` baked into the message text instead of a scope property.
- Logging a secret, API key, token, or `Authorization` header value at any level, in any form.
- Hardcoding a sink credential in a committed `appsettings*.json`.
- Manually re-logging `Application`/`Environment`/`Version`/etc. as call-site arguments.
- Switching the dev Console sink to JSON, or the prod Console sink to plain text.
