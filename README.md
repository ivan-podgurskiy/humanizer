# Humanizer

[![CI](https://github.com/ivan-podgurskiy/humanizer/actions/workflows/ci.yml/badge.svg)](https://github.com/ivan-podgurskiy/humanizer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Human-friendly formatting for Elixir. One flat module of pure functions that turn
raw values into the strings you actually show to people — file sizes, durations,
relative time, large numbers, ordinals and list enumerations.

English-only, zero configuration, no global state. Replaces a handful of
single-purpose dependencies (`filesize`, `humanize_time`, ad-hoc helpers) with one.

## Installation

Add `humanizer` to your `mix.exs`:

```elixir
def deps do
  [
    {:humanizer, "~> 0.1.0"}
  ]
end
```

## Quick start

```elixir
Humanizer.bytes(2_456_789)
# => "2.5 MB"
Humanizer.bytes(2_456_789, system: :binary)
# => "2.3 MiB"

Humanizer.duration(3725)
# => "1 hour, 2 minutes"
Humanizer.duration(45, format: :short)
# => "45s"

Humanizer.relative_time(~U[2026-05-13 10:00:00Z], ~U[2026-05-15 10:00:00Z])
# => "2 days ago"

Humanizer.number(1_234_567)
# => "1.2M"

Humanizer.ordinal(23)
# => "23rd"

Humanizer.list_join(["Alice", "Bob", "Charlie"])
# => "Alice, Bob and Charlie"
```

Every function takes its options as a keyword list — there is no `Application` env
and nothing to configure globally.

## API

| Function | Example | Result |
|---|---|---|
| `bytes/2` | `Humanizer.bytes(2_456_789)` | `"2.5 MB"` |
| `duration/2` | `Humanizer.duration(3725)` | `"1 hour, 2 minutes"` |
| `relative_time/2,3` | `Humanizer.relative_time(past, now)` | `"2 days ago"` |
| `number/2` | `Humanizer.number(1_234_567)` | `"1.2M"` |
| `ordinal/1` | `Humanizer.ordinal(23)` | `"23rd"` |
| `list_join/2` | `Humanizer.list_join(["a", "b", "c"])` | `"a, b and c"` |

Numbers use one consistent rule: round-half-away-from-zero with a single fractional
digit by default (override with `:precision`). Output is never in scientific
notation, for any input up to `10 ** 15`.

## Localization

**English only in v0.1.** This is deliberate. Real localization means pluralization,
gender, grammatical cases and locale-specific decimal separators — a single `bytes/1`
under locales is a project of its own.

If you need serious internationalization, use
[`ex_cldr`](https://hex.pm/packages/ex_cldr) and
[`ex_cldr_numbers`](https://hex.pm/packages/ex_cldr_numbers). Localization may arrive
in a later version as an optional layer, but it is out of scope here.

## Comparison

Humanizer is not "better than everything". It replaces four or five small
dependencies with one, _if English output is enough for you_.

| You need | Use |
|---|---|
| One package for all small English formatting | **Humanizer** |
| Only file sizes | [`filesize`](https://hex.pm/packages/filesize), [`sizeable`](https://hex.pm/packages/sizeable) |
| Times/durations with i18n | [`timex`](https://hex.pm/packages/timex) + manual localization |
| Pluralize, singularize, camel/snake case | [`inflex`](https://hex.pm/packages/inflex) |
| Full number/date localization (CLDR) | [`ex_cldr`](https://hex.pm/packages/ex_cldr) + `ex_cldr_numbers` |
| Parsing human time back into values | [`chronic`](https://hex.pm/packages/chronic) |

## License

MIT. See [LICENSE](LICENSE).
