# Roadmap

This roadmap is a statement of intent, not a promise — items move based on real
usage and issues.

Guiding constraints (unchanged from v0.1):

- **English only** until a deliberate localization release.
- **One flat `Humanizer` module.** No `Humanizer.Bytes` / `Humanizer.Time`
  submodules. If the surface keeps growing, that is the signal to stop adding,
  not to split.
- **No `Application` env.** Every option is a keyword list on the function.
- **No scientific notation, one rounding rule** (round half away from zero,
  one fractional digit by default, `:precision` to override).
- Every public function ships with `@doc` + `@spec` + ≥2 doctests, and every
  edge case gets a dedicated test.

---

## v0.1.1 — correctness polish (released)

- [x] Fix magnitude carry-over in `bytes/2` and `number/2` so rounding advances
      the unit instead of emitting a `1000.x` mantissa (`999_950` → `"1.0 MB"`,
      `999_999` → `"1.0M"`).
- [x] Tighten the `bytes/2` property test to reject a `1000.x` mantissa.

## v0.2.0 — fill the obvious English gaps (additive, backward-compatible) (released)

The most-requested category functions that need zero i18n and fit the existing
philosophy. Ordered by priority.

- [x] **`delimit/2`** — thousands separator: `1_234_567` → `"1,234,567"`.
      The single most common "humanize" helper still missing. Options:
      `:separator` (default `","`), `:precision` for floats. Highest priority.
- [x] **`truncate/3`** — string truncation with an ellipsis and an optional
      word boundary: `truncate("the quick brown fox", 9)` → `"the quic…"`.
      Options: `:omission` (default `"…"`), `:break` (`:char` | `:word`).
- [x] **`list_join/2` `:max` option** — collapse long lists:
      `list_join(names, max: 2)` → `"Alice, Bob and 3 others"`.
      Option for the trailing noun (`:other` / `:others`).
- [x] **`relative_time` improvements** — weeks / months / years approximations
      beyond the current day ceiling and a `:format` option (`:short` → `"2d ago"`).
      Months/years here are coarse approximations for display only, distinct from
      the deliberately omitted calendar math in `duration/2`. Finer near-now
      granularity (`"a moment ago"`) was deferred: the sub-minute window stays
      `"just now"` to keep v0.1 output backward-compatible.

Candidates pending demand (do not build speculatively):

- `percentage/2` — `0.1234` → `"12.3%"`.
- `ordinal_words/1` — `3` → `"third"` (small, but starts down the word-form path).

## v0.3.0 — localization layer (only if v0.1/v0.2 see real adoption)

English stays the zero-dependency default. Localization arrives as an
**optional** layer, never a hard dependency.

- [ ] Decide between two shapes:
      1. `:locale` option backed by an optional `ex_cldr` dependency, or
      2. a separate `humanizer_cldr` companion package.
- [ ] Whichever is chosen, the core `Humanizer` API and its English behavior
      must not change for users who pass no locale.

---

## Explicitly out of scope (continue to defer)

These are intentionally *not* on the roadmap; they belong to other packages or
would break the "small, flat, pure" contract:

- Calendar months/years in `duration/2` (non-linear, needs a reference point).
- Quadrillions and beyond in `number/2` (`T` is the v0.1 ceiling).
- Pluralization / singularization — use [`inflex`](https://hex.pm/packages/inflex).
- Word-form numbers (`"forty-two"`) — a separate, harder package.
- Parsing human strings back into values (`"2 hours"` → `7200`) — `chronic`.
- Telemetry — nothing here is worth instrumenting.
