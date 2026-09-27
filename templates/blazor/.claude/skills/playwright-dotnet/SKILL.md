---
name: playwright-dotnet
description: End-to-end UI testing for a Blazor app with Microsoft.Playwright (.NET). Use when writing or running browser-based E2E/regression tests.
paths:
  - "tests/**"
---

# Playwright (.NET) E2E

For end-to-end testing of the Blazor UI (and the API behind it). Use **Microsoft.Playwright** (.NET binding), not the Node CLI.

## Setup (when adding E2E to a repo)
- Add a dedicated test project referencing `Microsoft.Playwright` (+ its NUnit/xUnit integration package).
- Install browsers: `pwsh bin/Debug/<tfm>/playwright.ps1 install`.
- Run against a non-production environment with seeded, deterministic data.

## Core API
```csharp
using var playwright = await Playwright.CreateAsync();
await using var browser = await playwright.Chromium.LaunchAsync(new() { Headless = true });
var page = await browser.NewPageAsync();
await page.GotoAsync(baseUrl);
await page.GetByLabel("Email").FillAsync(user);
await page.GetByRole(AriaRole.Button, new() { Name = "Login" }).ClickAsync();
await Expect(page.GetByText("Dashboard")).ToBeVisibleAsync();
```

## Blazor Specifics
- Prefer **web-first assertions** (`Expect(...).ToBeVisibleAsync()`) that auto-wait, over fixed `WaitForTimeout` — Blazor UI updates asynchronously (SignalR circuit, or a WASM/Auto hydration handoff), and a fixed wait is both flaky and slow.
- If the app uses `InteractiveAuto`: there's a hydration moment as the page moves from the server-rendered phase to WASM. Don't assert on dynamic data until the WASM runtime has finished loading — auto-waiting assertions handle this correctly; a fixed timeout doesn't.
- If the app uses Blazor Server: wait for the circuit to connect before interacting — assert on rendered state, not on network activity.
- Component-library grids (Radzen, MudBlazor, etc.) render rich DOM — locate by role/text/`data-*` attribute rather than brittle CSS chains. Use `GetByRole`, `GetByText`, `GetByLabel`.
- Auth tokens are commonly stored in browser local storage — test the login flow end-to-end before asserting on protected pages, rather than injecting a token directly.

## Scenarios to Cover
- Auth: login, logout, and (if applicable) token refresh; role-based access control — verify the server actually blocks a lower-privileged user, not just that the UI hides a button.
- Core CRUD flows for the app's primary entities (e.g. Order/Customer/Product create → edit → delete).
- Grid sort/filter/paging; dialog/popup content components submit correctly.
- Form validation error messages surface and clear correctly.
- Any multi-step workflow specific to the app (e.g. a status pipeline: create → transition → close).

## Rules
- Deterministic seeded data; clean up after the run. Never run against production.
- Don't assert on volatile values (timestamps, generated IDs) without tolerance.
- Keep tests independent; one user journey per test. File defects with a repro via `debugger`.
