# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-05-31

### Fixed

- `bytes/2` and `number/2` now carry up to the next unit when rounding would
  otherwise produce a mantissa of `1000` (e.g. `999_950` → `"1.0 MB"` instead of
  `"1000.0 KB"`, `999_999` → `"1.0M"` instead of `"1000.0K"`).

## [0.1.0] - 2026-05-31

### Added

- `bytes/2` — human-readable file sizes with decimal (SI) and binary (IEC) units.
- `duration/2` — durations in seconds formatted as words (days down to seconds),
  with `:units` and `:format` options.
- `relative_time/2,3` — `DateTime` formatted relative to now or a reference time
  (`"2 days ago"`, `"in 3 hours"`, `"just now"`).
- `number/2` — large numbers with `K`/`M`/`B`/`T` suffixes.
- `ordinal/1` — English ordinals, correctly handling the 11/12/13 exceptions.
- `list_join/2` — human-readable list enumeration with optional Oxford comma and
  custom conjunction.
- English-only, zero-config, scientific-notation-free formatting throughout.

[0.1.1]: https://github.com/ivan-podgurskiy/humanizer/releases/tag/v0.1.1
[0.1.0]: https://github.com/ivan-podgurskiy/humanizer/releases/tag/v0.1.0
