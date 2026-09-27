---
paths:
  - "src/**/*Validator.cs"
  - "src/**/Identity*/**/*.cs"
  - "src/**/Auth*/**/*.cs"
---
# Validation & Authorization Rules

## Validation (FluentValidation)
- Form/input validation uses **FluentValidation**. One validator per ViewModel/Request: `class XViewModelValidator : AbstractValidator<XViewModel>`.
- Validators live next to the type they validate in the Presentation layer (e.g., `Orders/List/OrderItemViewModelValidator.cs`).
- **Length/range limits come from Domain `Consts` rules**, never magic numbers: `MaximumLength(OrderValidationRules.Name_Max)`. This keeps UI validation and EF `HasMaxLength` in sync with the same source of truth.
- Messages come from shared resources (e.g. `ResxValidation.FieldNotEmpty`, `ResxValidation.FieldToLong`, `ResxValidation.FieldToShort`) — do NOT hardcode user-facing strings. Add a resource entry if a message is missing.
- Three validation layers, each with a job:
  1. **UI validator (FluentValidation)** — fast feedback on forms.
  2. **Domain invariants** — entity factories/methods guard with `ArgumentException.ThrowIfNullOrEmpty(...)` etc. The domain is the last line of defense and must not trust the UI.
  3. **Handler business checks** — uniqueness/existence returned as `Result` + an error code, not exceptions.
- Keep the three consistent: a field's max length appears once (Domain const) and is referenced by both the validator and the EF config.

## Authentication
- Pick one scheme per app and be explicit about it — e.g. JWT Bearer for an API, or cookie-based auth with an external OAuth provider for a server-rendered UI. Don't mix schemes without a reason.
- Current user identity is resolved through an abstraction such as `ICurrentUserService`/`ICurrentUserContext` — never from raw `HttpContext` in application/domain code.
- Passwords are hashed via `IPasswordHasher` — never store or log plaintext passwords.
- Recovery/reset password flows use time-limited, single-use tokens or hash codes — never a long-lived secret.

## Authorization
- Define roles/permissions as an enum (e.g. `Role` with `Administrator`, `Manager`) or a policy-based scheme. Authorize by role/policy, not by hardcoded user identifiers.
- Protect endpoints/pages by role; default-deny. A lower-privileged user must not reach higher-privileged operations — enforce on the server (handler/endpoint), not just by hiding UI.
- Authorization is a server concern. Hiding a button is UX, not security — the corresponding handler/endpoint must re-check the caller's role.

## Anti-Patterns
- Hardcoded validation limits or user-facing strings.
- Trusting client input in handlers/domain without re-validation.
- Role checks only in the UI; missing server-side enforcement.
- Throwing for expected validation failures instead of `Result<T>` + an error code.
- Storing or logging plaintext passwords or tokens.
