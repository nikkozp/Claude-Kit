---
name: uiux-design-system
description: Design token architecture, layout/spacing, typography, color/theming, density, accessibility for a Blazor UI. Use when designing or reviewing any UI screen or touching global CSS.
paths:
  - "src/**/*.razor"
  - "**/wwwroot/css/**"
---

# UI/UX Design System

Design tokens and principles for the app's UI. This is the shared vocabulary UI reviews go
against and components implement to — not a generic UI textbook, but this codebase's
conventions. Library-agnostic: applies whatever component library (or none) the project uses.

## Design Principles
- Match density and tone to the audience: a back-office/admin surface favors information
  density and scanning speed; a customer-facing surface favors whitespace and guided flow.
  State which one a screen is before applying spacing/density choices.
- Consistency beats novelty: reuse an existing pattern (list item card, grid column set,
  toolbar layout) before inventing a new one.
- Every screen must work identically in light and dark — a design isn't done until both are
  checked.

## Token Architecture
- All design tokens are CSS custom properties defined on `:root` in a single stylesheet (e.g.
  `wwwroot/css/design-system.css`), loaded before component-isolation CSS. Never hardcode a hex
  color or pixel spacing value in a `.razor`/`.razor.css` file when a token already expresses
  it — add a token before adding a one-off value.
- If the project layers a component library with its own CSS variables (e.g. `--rz-*`,
  `--mud-*`), bridge your tokens to those variables rather than maintaining two independent
  palettes that can drift apart in dark mode.
- Example token shape:
  ```css
  :root {
    --color-surface-0: #ffffff;
    --color-surface-1: #f4f5f7;
    --color-text-primary: #1a1a1a;
    --color-text-secondary: #5f6368;
    --color-border: #d9dbe0;
    --color-accent: #2f6feb;
    --color-success: #157347;
    --color-danger: #b3261e;
    --color-warning: #a15c00;

    --space-xs: 0.25rem;
    --space-sm: 0.5rem;
    --space-md: 1rem;
    --space-lg: 1.5rem;
    --space-xl: 2rem;

    --font-size-xs: 0.75rem;
    --font-size-sm: 0.875rem;
    --font-size-base: 1rem;
    --font-size-lg: 1.25rem;
    --font-size-xl: 1.5rem;
    --font-size-2xl: 2rem;
  }

  @media (prefers-color-scheme: dark) {
    :root {
      --color-surface-0: #1a1c1e;
      --color-surface-1: #232629;
      --color-text-primary: #e8e9eb;
      --color-text-secondary: #a7abb2;
      --color-border: #3a3d42;
    }
  }
  ```

## Layout & Spacing
- Use the spacing scale (`--space-*`) for margins/padding/gaps — don't hand-roll pixel values
  in isolated CSS when a token already expresses it.
- Favor flex/grid-based composition over nested fixed-width containers; let content reflow
  rather than clipping at fixed breakpoints.
- Group related actions in one toolbar/row; don't scatter primary and secondary actions across
  a screen.

## Typography
- Pick one base font family for the app and wire it once at the root; don't introduce a second
  family or a one-off `font-size` in markup.
- Use the type scale (`--font-size-*`) — if it's missing a step, add a token, don't hardcode.
- Reserve bold/large headings for section titles, not for emphasis inside body text.
- Tabular numeric columns (prices, counts, IDs) should use `font-variant-numeric:
  tabular-nums` so values don't reflow in width as they change.

## Color & Theming
- Drive light/dark from a single mechanism: either `prefers-color-scheme` or one explicit
  `data-theme`/`data-bs-theme` attribute + a small script that toggles it and persists the
  choice. Never introduce a second, independent theme mechanism alongside it.
- Status/semantic color (success/danger/warning) comes from the semantic tokens above, applied
  via a small set of utility classes or a shared helper — never a hardcoded hex in markup.
- Contrast target: **WCAG AA** (4.5:1 for normal text, 3:1 for large text/UI components) in
  both themes — check the dark variant separately, it is not guaranteed by checking light
  alone.
- Never signal status by color alone — pair it with an icon or a text label.

## Density & Components
- Pick a row/cell density appropriate to the screen's purpose (compact for scanning many rows,
  spacious for a small curated list) and apply it consistently across all data grids/tables in
  the app, not per-instance.
- Prefer a data-grid/table component for anything tabular; reserve card-based layouts for list
  items that need richer per-row content (badges, icons, inline actions) than a table cell
  comfortably shows.
- Empty/loading/error states are part of the design, not an afterthought — every data-bound
  screen needs all three considered, not just the happy path.

## Accessibility
- Icon-only buttons need an `aria-label` or visible tooltip text — never ship a bare icon
  button with no accessible name.
- Interactive elements must show a visible focus state; don't suppress the browser's focus
  outline without providing a replacement.
- Keyboard operability: dialogs, dropdowns, and custom components must be reachable and
  operable via keyboard (Tab/Enter/Esc), not mouse-only.
- Respect logical tab order — it should match visual reading order (top-to-bottom,
  left-to-right), not DOM insertion order if that diverges from layout.

## Checklist
- [ ] Verified in both light and dark theme
- [ ] Spacing/typography use tokens, not hand-rolled values
- [ ] Status conveyed by color + icon/label, never color alone
- [ ] Contrast meets WCAG AA in both themes
- [ ] Icon-only controls have accessible names; focus states visible; keyboard-operable
- [ ] Reuses an existing pattern/component before introducing a new one

See `.claude/rules/blazor.md` for component-level conventions, and the `uiux-designer` and
`blazor-expert` agents for review/implementation of this system.
