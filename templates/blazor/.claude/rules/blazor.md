---
paths:
  - "src/**/*.razor"
  - "src/**/*.razor.cs"
---
# Blazor Rules

Conventions for Razor components. UI library, hosting model, and design tokens are project-specific — check `Program.cs`/`.csproj` for the render mode (Server, WebAssembly, or Auto) and the installed UI package before assuming either. See `blazor-expert` for hosting-model detection guidance.

## Component Structure
- **Code-behind pattern.** Markup in `Component.razor`; logic in `Component.razor.cs` as `public partial class`. Keep them paired. `@code { }` blocks in the `.razor` file are acceptable for small components — follow whatever the surrounding feature already does.
- Inject services with `[Inject] private IService _service { get; set; } = default!;`.
- Components are **thin**. No aggregations, joins, `GroupBy`/`SelectMany`, or heavy LINQ in `@code`/code-behind. If the UI needs shaped data, request it from the layer that owns query/use-case logic — see `.claude/rules/architecture.md` — rather than shaping it client-side.
- **Avoid chatty UI** — one consolidated query per view rather than several calls stitched together in the component.

## Componentization
- No monolithic `.razor` files. When you'd add a `@* Section *@` comment to separate a block, extract that block into its own component instead.
- Data down via `[Parameter]`; events up via `[Parameter] public EventCallback<T> OnX { get; set; }`.
- **Popups/Modals/Dialogs:** never put complex markup or forms directly in a dialog body — extract a dedicated content component and pass it in (e.g., via a template parameter).

## ViewModels & Mapping
- UI-shaping types are suffixed `ViewModel` (not `Model`), e.g. `OrderCardViewModel`.
- Map DTO/response → ViewModel through a mapper (AutoMapper profile, static extension methods, or hand-written mapper class — match whatever the project already uses). Never build a ViewModel inline field-by-field inside a page or component; add or extend a mapper method instead.

## Forms & Validation
- Use `EditForm` (or the UI library's form component) bound to a ViewModel.
- Validate with FluentValidation (`XViewModelValidator : AbstractValidator<XViewModel>`, co-located with the ViewModel) when the project uses FluentValidation, or the built-in `DataAnnotationsValidator` otherwise — check what's already referenced before introducing a new validation approach.
- Confirm destructive actions with a confirmation dialog before executing them.
- Reusable forms are sub-components that take `[Parameter] TViewModel Data`, `EventCallback<TViewModel> OnSubmit`, and `EventCallback OnCancel`; create and edit pages wrap the same form component.

## Grids & Tables
- Use the project's single sanctioned grid/table component consistently — don't mix a raw `<table>` with a UI-library grid, and don't introduce a second grid library alongside an existing one. Check what's already used in the codebase before adding a new dependency.
- After a mutation, reload the grid's data source rather than manually re-fetching and re-binding.

## Lifecycle & Rendering
- Load data in `OnInitializedAsync` / `OnParametersSetAsync`, or `OnAfterRenderAsync(firstRender)` when the codebase already uses that pattern for first-render loads (common when JS interop or hydration timing matters). Guard against null parameters.
- Observable/Rx UI updates MUST go through `InvokeAsync(StateHasChanged)`, never a bare `StateHasChanged()` call from an off-render-flow callback (timer, subscription, background task) — see `blazor-server-gotchas` for why this differs by render mode.
- Override `ShouldRender()` when it prevents wasteful re-renders of expensive components.
- Never `async void` except DOM/UI event handlers.

## Disposal
- Implement `IDisposable`/`IAsyncDisposable` for any component that subscribes to events, timers, or observables.
- Use `CompositeDisposable` (or equivalent) to track subscriptions and dispose them together; `.DisposeMany()` after transforming a stream into disposables (Rx/DynamicData).
- Dispose JS interop object references (`IJSObjectReference`) in `DisposeAsync`.

## State
- Don't keep sensitive data in long-lived component or service state longer than needed. In WASM and Auto hosting, component state can live in the browser; in Server hosting, it lives per-circuit on the server for as long as the connection is open — either way, undisposed subscriptions or oversized cached state leak for the session/circuit lifetime.
- Prefer passing state down via `[Parameter]` or a scoped state service over static/global mutable state.

## Markup Cleanliness
- NEVER inline C# ternaries for CSS classes in markup (`class="@(x > 0 ? "a" : "b")"` is forbidden). Extract to a helper method or a code-behind property: `class="@CssHelper.GetStatusCssClass(status)"`.
- Prefer isolated CSS (`Component.razor.css`) for component-specific styling; use the project's utility CSS framework (if any) for layout.

## JS Interop
- Only call `IJSRuntime`/`IJSObjectReference` methods after the component has rendered (`OnAfterRenderAsync`) — JS interop is unavailable during prerendering and, in Server/Auto hosting, before the circuit is connected.
- Wrap interop calls made during startup or prerender in a guard or try/catch; don't assume `IJSRuntime` is usable in `OnInitializedAsync`.
- Dispose `IJSObjectReference` instances you create.

## Localization
- No hardcoded user-visible strings in markup or code-behind. Source them from `.resx` resource files (e.g. neutral + per-culture `.xx.resx`), generated as strongly-typed accessor classes.
- Add every new resource key to all culture files the project maintains, not just the default.
- Format dates/numbers explicitly and culture-aware; don't rely on implicit `ToString()` formatting for user-facing values.

## Authorization
- Page-level role checks use `@attribute [Authorize(Roles = ...)]`; element-level checks use `<AuthorizeView>`.
- Hiding UI is UX only — the API/backend is the source of truth for authorization. Never treat a hidden button as a security control.

## Anti-Patterns
- Heavy LINQ, grouping, or aggregation inside a component's code-behind.
- A page or component bypassing the project's data-access abstraction (facade/handler/service) to call an HTTP client or data layer directly.
- Hardcoded strings in markup or toasts instead of resource keys.
- Mixing two UI component libraries, or reintroducing a library the project has migrated away from.
- Undisposed subscriptions, timers, or JS object references.
