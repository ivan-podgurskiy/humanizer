# Humanizer LiveView Demo Design

## Purpose

Build a polished, production-ready Phoenix LiveView application in `demo/` that
serves two roles on one English-language page:

1. a public showcase that explains the value and constraints of Humanizer; and
2. an interactive playground for every public function and option in Humanizer
   v0.3.0.

The demo is committed in the Humanizer repository but remains an independent
Mix project. It depends on the library with `{:humanizer, path: ".."}` and must
not be included in the Hex package.

## Product Direction

Use the approved **Editorial Lab** direction: an editorial landing page with a
strong opening statement, live code proof, restrained lime accents, and a bento
playground that feels useful rather than decorative.

The page copy is English because Humanizer is deliberately English-only. The
demo itself does not introduce an interface-localization layer.

## Scope

### Included

- A standalone Phoenix LiveView application under `demo/`.
- A public `/` route combining the showcase and playground.
- Interactive coverage of all nine Humanizer functions and all documented
  options.
- Synchronized output and safe Elixir code examples.
- Presets that demonstrate normal and boundary behavior.
- Responsive light and dark appearances.
- Accessible native form controls and keyboard operation.
- A stateless `/health` endpoint.
- A production Phoenix release and multi-stage Docker image.
- Local, test, release, and Docker instructions.
- CI coverage for the library, demo, production assets, release, and Hex
  package contents.

### Excluded

- Ecto, a database, user accounts, authentication, saved sessions, analytics,
  background jobs, and telemetry.
- A JavaScript SPA or JSON API.
- User-supplied Elixir evaluation.
- Localization of either Humanizer output or the demo interface.
- Hosting-provider-specific manifests.
- Changes to the Humanizer public API.

## Repository and Packaging

The existing root remains the Hex library project. `demo/` has its own
`mix.exs`, `mix.lock`, config, assets, tests, and release files. Its dependency
on Humanizer is a path dependency so every interaction executes the checked-out
library code.

The existing root `package[:files]` allowlist does not contain `demo/`, so Hex
already excludes it. CI must additionally run `mix hex.build` at the root and
inspect the archive contents to prevent future packaging regressions.

The existing user change to `.tool-versions` is preserved. Generated visual
brainstorming files under `.superpowers/` are ignored and are not part of the
delivered demo.

## Technical Architecture

The demo targets Elixir `~> 1.18` and a compatible Phoenix 1.8 / LiveView 1.2
stack. It is generated without Ecto, mailer, dashboard, or other unused
subsystems.

The application has four principal boundaries:

1. **`HumanizerDemoWeb.PlaygroundLive`** owns URL rendering, current form state,
   per-card LiveView events, presets, and disclosure state.
2. **`HumanizerDemo.Playground`** is a pure dispatcher. It accepts a formatter
   identifier and raw string parameters and returns a typed result containing
   normalized form state, formatted output, generated code, and field errors.
3. **Input and code helpers** parse raw browser values without evaluation and
   render deterministic Elixir snippets from validated values.
4. **Playground components** render the shared card frame, controls, output,
   error state, code block, copy control, and presets. Function-specific
   controls remain explicit so the UI documents the real API instead of hiding
   it behind generic schema rendering.

There is no persistent application state. Reloading the page resets the
playground to curated defaults.

## Page Structure

### Navigation

A compact top bar contains the Humanizer wordmark, an anchor to the playground,
links to GitHub and HexDocs, and a copyable installation snippet:

```elixir
{:humanizer, "~> 0.3.0"}
```

External links are clear and keyboard-accessible. The navigation collapses
cleanly on small screens without creating a separate mobile application shell.

### Hero

The hero leads with “Raw values in. Clear language out.” and a short description
of the library's pure, zero-configuration contract. A live `bytes/2` example
provides immediate proof that the page is interactive.

The hero avoids vanity metrics and fabricated adoption claims. Its supporting
facts are limited to properties demonstrable from the package: nine helpers,
English-only output, pure functions, zero global configuration, consistent
rounding, and no scientific notation within documented bounds.

### Playground Chapters

The nine cards are organized into four readable chapters:

- **Size:** `bytes/2`.
- **Numbers:** `number/2`, `percentage/2`, `delimit/2`, and `ordinal/1`.
- **Time:** `duration/2` and `relative_time/2,3`.
- **Text & Lists:** `truncate/3` and `list_join/2`.

Every card displays its function name, one-sentence purpose, primary inputs,
large formatted result, synchronized Elixir call, copy button, and curated
presets. Advanced options use native disclosure controls when keeping them open
would make the full page visually noisy.

### Closing Context

The final section sets correct expectations: Humanizer is English-only, does
not parse formatted text, and is intentionally smaller than a CLDR solution. It
links to the package documentation and source without presenting competing
libraries as inferior.

## Complete API Coverage

### `bytes/2`

- Non-negative integer byte count.
- `system`: `:decimal` or `:binary`.
- `precision`: non-negative integer.
- Presets include zero, a value below the first boundary, a carry-over rounding
  case, binary output, and a petabyte-scale value.

### `number/2`

- Integer or float, including negative values.
- `precision`: non-negative integer.
- Presets include zero, 999, the 1,000 boundary, a negative value, a rounding
  carry case, and a trillion-scale value.

### `percentage/2`

- Ratio input, with visible copy explaining that `1` means `100%`.
- `precision`: non-negative integer.
- Presets include zero, a fractional ratio, one, a negative half-away rounding
  case, and a ratio greater than one.

### `delimit/2`

- Integer or float.
- `separator`: editable string.
- `precision`: either natural decimals or a non-negative fixed precision.
- Presets include an integer, negative integer, natural float, currency-like
  fixed precision, and a custom separator.

### `ordinal/1`

- Integer input, including negative values.
- Presets explicitly demonstrate 1/2/3, the 11/12/13 exceptions, 21/22/23,
  zero, and a negative ordinal.

### `duration/2`

- Non-negative seconds, including fractional sub-second input.
- `units`: one through four, or `:all`.
- `format`: `:long` or `:short`.
- Presets include zero, less than one second, 45 seconds, multiple units, and a
  large value that remains expressed in days.

### `relative_time/2,3`

- Explicit value and reference datetimes for reproducible results.
- `format`: `:long` or `:short`.
- A “Use current UTC time” action updates the reference only when requested; no
  background timer continuously changes output.
- Presets cover just now, past, future, week, month, and year approximations.

### `truncate/3`

- Unicode text and non-negative maximum grapheme length.
- `omission`: editable marker.
- `break`: `:char` or `:word`.
- Presets cover unchanged text, mid-word truncation, word boundaries, custom
  omission, an omission as long as the limit, and multibyte graphemes.

### `list_join/2`

- One item per input line; blank lines are excluded from the evaluated list.
- `conjunction`: editable text.
- `oxford`: boolean.
- `max`: disabled or a positive integer.
- `other` and `others`: editable singular and plural remainder nouns.
- Presets cover empty, one-item, two-item, Oxford-comma, alternate conjunction,
  and collapsed-list results.

## Data Flow and Validation

Each card submits its own `phx-change` event with a modest debounce on text and
numeric inputs. The event includes a fixed formatter identifier; the server
does not accept arbitrary module or function names.

`HumanizerDemo.Playground.evaluate/2` parses the raw parameter map, validates
the formatter-specific contract, calls the public Humanizer function, and
returns the card's next state. Validated options are the single source for both
the Humanizer call and displayed code snippet, preventing the two outputs from
drifting.

The browser never sends or evaluates Elixir syntax. Code snippets escape string
content and use deterministic literal rendering. `ArgumentError` is caught only
at the playground boundary and converted into a card-local error; programmer
errors are not silently swallowed.

Invalid values keep the raw user input visible, add a concise inline field
message, and preserve the card's last valid result. A failure in one card does
not affect any other card or disconnect the LiveView.

## Interaction Details

- Form changes update only the relevant card.
- Presets populate every affected control and immediately produce the expected
  output and code.
- Copy controls use a tiny JavaScript hook around the Clipboard API, expose a
  short success state, and leave all formatting logic on the server.
- Native inputs, selects, buttons, and disclosure elements retain browser focus
  behavior.
- Every input has a visible label and every error is associated with its field.
- Motion is limited to short state and disclosure transitions and respects
  `prefers-reduced-motion`.

## Visual System

The visual language is editorial rather than dashboard-like:

- warm paper-like neutral surfaces;
- dark, high-contrast ink;
- a restrained lime accent for active controls and live output;
- expressive display typography for headlines and a legible monospace face for
  code and values;
- thin borders, modest radii, and limited shadow;
- varied bento spans on wide screens, collapsing to one column on mobile.

The implementation follows `prefers-color-scheme` for a complete dark
appearance. It does not add a theme toggle because theme persistence is outside
the stateless demo's purpose. No font or UI framework CDN is required at
runtime.

The layout must work without horizontal scrolling at 320 CSS pixels and retain
a deliberate hierarchy on wide desktop displays.

## HTTP and Runtime Behavior

`GET /health` returns a small `200` text response and does not require a
LiveView session. It is suitable for Docker's healthcheck and basic platform
probes.

Production runtime configuration reads:

- `PHX_SERVER` to enable the web endpoint in a release;
- `PHX_HOST` for the public host;
- `PORT` for the listening port; and
- `SECRET_KEY_BASE` for session signing.

Missing required production secrets fail at startup with an actionable error.
No database URL or migration step exists.

## Docker and Release

The multi-stage Dockerfile uses pinned Elixir/OTP build and minimal runtime
images compatible with the repository's Elixir 1.18 and OTP 27 baseline. Its
Dockerfile-specific ignore rules live in `demo/Dockerfile.dockerignore` because
the build context must be the repository root for the path dependency. The
builder installs dependencies, compiles production code, builds assets, and
creates a release. The final image contains the release and required OS runtime
libraries but no source checkout, Mix, or Node.js.

The final container runs as a dedicated unprivileged user, exposes the Phoenix
port, and uses `/health` for its healthcheck. The Docker build context is the
repository root so the path dependency is available during compilation.

## Testing Strategy

### Pure playground tests

For every formatter, tests cover:

- its default example;
- every public option;
- representative edge presets;
- parse and validation failures;
- safe, matching Elixir code output; and
- preservation of the last valid result after invalid input where applicable.

### LiveView tests

LiveView tests verify:

- all nine formatter cards render at `/`;
- the initial hero and installation snippet are present;
- each card updates independently;
- presets update controls, result, and code together;
- invalid input stays local to its card;
- advanced options can be reached with keyboard-operable controls; and
- required labels, heading hierarchy, and error associations are present.

### HTTP, release, and packaging tests

- The health controller returns `200` and the expected content type and body.
- `mix assets.deploy` and `mix release` succeed in production mode.
- The Docker image builds and its healthcheck command targets `/health`.
- Root `mix hex.build` succeeds and the produced archive contains no `demo/`
  paths.

## Continuous Integration

The existing root library matrix remains intact. A focused demo job uses the
repository's primary Elixir 1.18 / OTP 27 combination to run:

1. dependency installation;
2. compilation with warnings as errors;
3. formatting verification;
4. demo tests;
5. production asset compilation; and
6. production release creation.

A packaging step at the root verifies the Hex archive exclusion. Docker build
validation may reuse the primary demo job or run as a separate job when cache
behavior makes that clearer.

## Documentation

`demo/README.md` contains exact commands for:

- installing demo dependencies;
- starting the LiveView server locally;
- running tests and formatting checks;
- building and starting a local production release;
- building and running the Docker image from the repository root; and
- supplying the four runtime environment variables.

The root README gains a concise “Interactive demo” section linking to `demo/`
and explaining that the demo is intentionally excluded from the Hex package.

## Acceptance Criteria

The work is complete when:

1. `demo/` starts independently and calls the root Humanizer path dependency.
2. The single page visibly combines the approved Editorial Lab showcase and a
   usable playground.
3. Every public Humanizer function and documented option is interactive.
4. Invalid input cannot crash or disconnect the page.
5. The page is usable at 320px, on desktop, with keyboard navigation, in light
   mode, and in dark mode.
6. The library and demo test suites, formatting, and warnings-as-errors checks
   pass.
7. Production assets and a Phoenix release build successfully.
8. The Docker image builds, runs without root privileges, and responds on
   `/health`.
9. The Hex archive builds without any `demo/` content.
10. Documentation allows a new contributor to reproduce local and production
    runs without undocumented steps.
