---
name: blazor-server-gotchas
description: Blazor Server and InteractiveAuto runtime pitfalls — circuit lifetime, dual-phase rendering, DbContext scope, threading, disposal, prerender. Use when debugging or building stateful components.
paths:
  - "src/**/*.razor"
  - "src/**/*.razor.cs"
---

# Blazor Server / InteractiveAuto Gotchas

Runtime traps specific to server-hosted Blazor rendering: **Blazor Server** (`InteractiveServer`, SignalR circuit) and, where the project uses it, **Blazor Web App `InteractiveAuto`** (server-first, then migrates to WASM). Check which one applies — see `blazor-expert`'s hosting-model detection — before applying a fix.

## Circuit & State (Server / Auto's server phase)
- Component state lives **per circuit (per connection)** on the server, not per request. A dropped connection disposes components — handle disposal and reconnection.
- Don't store large or sensitive objects in component fields longer than needed; it consumes server memory for every connected user.
- Long synchronous work blocks the circuit's UI thread — keep handlers async and offload heavy work to the application/service layer.

## The Dual-Phase Problem (InteractiveAuto only)
- A component first renders **interactively on the server** (SignalR circuit), then re-renders **in the browser** (WASM) once the WASM runtime finishes downloading. Both phases run the same component code.
- Services must be registered in **both** the host's `Program.cs` (server) and the `.Client` project's `Program.cs` (WASM). A missing registration causes a `NotSupportedException`/`InvalidOperationException` at runtime — but only in the phase where the registration is missing, so it can slip past a server-only smoke test.
- Any DI service that wraps server-only infrastructure (EF Core, a DB context factory, a message bus client) must **never** be injected into a component — in the WASM phase these types simply don't exist. Components should depend only on abstractions (facades/API clients) that work in both phases.
- `OnInitialized(Async)` can run **twice** in Auto mode: once on the server, once on WASM. If it fires an API call, that call fires twice. Guard with `OnAfterRenderAsync(firstRender)` or an explicit flag instead of relying on `OnInitializedAsync` alone.

## DbContext / EF (Server and Auto's server phase)
- NEVER inject a `DbContext` directly into a component and hold it — server-hosted components are long-lived, EF contexts must be short-lived. Go through the application/handler layer, which should create → use → dispose a context per operation (e.g. via `IDbContextFactory`).
- A context captured across `await` boundaries or multiple renders causes "context is being used by a second thread" errors and stale-data bugs.

## Threading & Rendering
- **Server phase / Blazor Server:** UI updates triggered outside a Blazor event (timers, observables, background callbacks) MUST be marshaled: `InvokeAsync(StateHasChanged)`. Calling `StateHasChanged()` off the circuit's synchronization context throws.
- **WASM phase:** the browser is single-threaded, so `StateHasChanged()` is always on the "right" thread and `InvokeAsync` is a safe no-op there.
- **Rule of thumb:** always use `InvokeAsync(StateHasChanged)` in subscriptions — it's correct in every hosting model:
  ```csharp
  .Subscribe(_ => InvokeAsync(StateHasChanged));
  ```
- `async void` only for DOM/UI event handlers; everywhere else `async Task`.
- Override `ShouldRender()` to avoid wasteful re-renders of expensive components.

## Disposal (memory leaks in every phase)
- Components that subscribe (Rx/DynamicData, events, timers, JS interop callbacks) MUST implement `IDisposable`/`IAsyncDisposable` and dispose a `CompositeDisposable`. Undisposed subscriptions leak for the circuit's lifetime (Server) or the browser session's lifetime (WASM/Auto).
- For DynamicData `.Transform(...)` into disposables, chain `.DisposeMany()`.
- Dispose `IJSObjectReference` instances you create.

## Lifecycle Order
- `OnInitialized(Async)` runs once per component instance (twice in Auto — see above); `OnParametersSet(Async)` on every parameter change — don't reload everything on every render. Guard against null parameters.
- `OnAfterRender(Async)(firstRender)` is the established pattern for JS interop and first-render data loads. JS interop is NOT available during prerendering, and (in Server/Auto) not until after the circuit connects.

## Auth
- Read the user via the project's `ICurrentUserService`/`AuthenticationStateProvider` abstraction, not `HttpContext` directly (it may be null after the initial render, and doesn't exist at all in WASM). Enforce role checks server-side (API/handler), not just by hiding UI.
- In Auto's server phase, browser storage (e.g. local storage) is not available during prerender — auth reads may return anonymous until hydration completes; wrap reads in a guard or move them to `OnAfterRenderAsync`.

## Checklist
- [ ] No long-lived `DbContext` in components (use the application/handler layer)
- [ ] Off-render-flow UI updates wrapped in `InvokeAsync(StateHasChanged)`
- [ ] Subscriptions and JS object references disposed via `IDisposable`/`IAsyncDisposable`
- [ ] Heavy work delegated to the application/service layer, not `@code`
- [ ] (Auto only) Service registered in both host and `.Client` `Program.cs`
- [ ] (Auto only) Initial data load guarded against firing twice (`firstRender` or an explicit flag)
