# Humanizer LiveView Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a polished, production-ready Phoenix LiveView application in `demo/` that showcases and interactively exercises every Humanizer v0.3.0 function and option.

**Architecture:** Keep the root Hex library unchanged and create a stateless Phoenix application with a path dependency on it. A pure `HumanizerDemo.Playground` boundary parses browser values, invokes Humanizer, and produces output/code/error state; one LiveView and focused function components render the Editorial Lab interface.

**Tech Stack:** Elixir 1.18, OTP 27, Phoenix 1.8.9, Phoenix LiveView 1.2.x, HEEx, esbuild, Tailwind-generated baseline replaced by project CSS, ExUnit, Docker multi-stage Phoenix release.

## Global Constraints

- The interface and all copy are English; no localization layer is added.
- The demo lives in `demo/` as an independent Mix project using `{:humanizer, path: ".."}`.
- The root Humanizer public API and root package file allowlist remain unchanged.
- The application has no Ecto, database, mailer, dashboard, accounts, analytics, jobs, or telemetry product behavior.
- User text is parsed as data and never evaluated as Elixir.
- All nine functions and every documented option are interactive.
- The page works at 320 CSS pixels, in light and dark system themes, and with keyboard navigation.
- Production requires `SECRET_KEY_BASE`, reads `PHX_HOST` and `PORT` with documented defaults, and uses `PHX_SERVER` to enable the release endpoint.
- The final container runs as a non-root user and exposes `/health`.
- Preserve the user's existing `.tool-versions` modification.
- Do not make intermediate commits; create one final commit only after the entire project passes verification.

---

## File Map

### Root files

- `.gitignore` — ignore `.superpowers/` brainstorming output and demo build artifacts not already covered by root patterns.
- `.github/workflows/ci.yml` — keep the library matrix and add demo, release, Docker, and Hex-content verification.
- `README.md` — link to the committed interactive demo project.
- `docs/superpowers/specs/2026-08-10-humanizer-liveview-demo-design.md` — approved design.
- `docs/superpowers/plans/2026-08-10-humanizer-liveview-demo.md` — this execution plan.

### Demo application and domain

- `demo/mix.exs`, `demo/mix.lock` — standalone Phoenix app and locked dependencies.
- `demo/config/*.exs` — development, test, production, and runtime configuration without database settings.
- `demo/lib/humanizer_demo/application.ex` — supervision tree.
- `demo/lib/humanizer_demo/playground.ex` — public dispatcher and result contract.
- `demo/lib/humanizer_demo/playground/catalog.ex` — formatter order, labels, defaults, and presets.
- `demo/lib/humanizer_demo/playground/parser.ex` — safe numeric, integer, datetime, option, and list parsing.
- `demo/lib/humanizer_demo/playground/code.ex` — deterministic Elixir-call rendering from validated values.
- `demo/lib/humanizer_demo/playground/evaluator.ex` — explicit Humanizer calls for all nine formatter identifiers.

### Demo web and assets

- `demo/lib/humanizer_demo_web.ex` — Phoenix web entry points.
- `demo/lib/humanizer_demo_web/endpoint.ex` — endpoint.
- `demo/lib/humanizer_demo_web/router.ex` — `/`, `/health`, and development-only routes.
- `demo/lib/humanizer_demo_web/controllers/health_controller.ex` — stateless health response.
- `demo/lib/humanizer_demo_web/controllers/error_html.ex` and `error_json.ex` — generated error rendering.
- `demo/lib/humanizer_demo_web/components/layouts.ex` and `layouts/root.html.heex` — minimal document shell and metadata.
- `demo/lib/humanizer_demo_web/components/playground_components.ex` — card frame, explicit controls, result/code panel, preset row, and field errors.
- `demo/lib/humanizer_demo_web/live/playground_live.ex` — state and events.
- `demo/lib/humanizer_demo_web/live/playground_live.html.heex` — Editorial Lab page composition.
- `demo/assets/css/app.css` — complete responsive visual system.
- `demo/assets/js/app.js` — LiveSocket plus Clipboard hook.
- `demo/priv/static/favicon.svg` — small code-native Humanizer mark.

### Demo tests and delivery

- `demo/test/humanizer_demo/playground_test.exs` — pure playground behavior.
- `demo/test/humanizer_demo_web/live/playground_live_test.exs` — complete interactive page behavior.
- `demo/test/humanizer_demo_web/controllers/health_controller_test.exs` — health contract.
- `demo/test/support/conn_case.ex` and `demo/test/test_helper.exs` — generated Phoenix test support.
- `demo/Dockerfile` and `demo/Dockerfile.dockerignore` — production image built from repository-root context.
- `demo/README.md` — exact local, release, and container instructions.

---

### Task 1: Scaffold the Independent Phoenix App and Health Contract

**Files:**
- Create: generated Phoenix application under `demo/`
- Modify: `demo/mix.exs`
- Modify: `demo/config/config.exs`
- Modify: `demo/config/runtime.exs`
- Modify: `demo/lib/humanizer_demo_web/router.ex`
- Create: `demo/lib/humanizer_demo_web/controllers/health_controller.ex`
- Create: `demo/test/humanizer_demo_web/controllers/health_controller_test.exs`

**Interfaces:**
- Consumes: root `Humanizer` project at path `..`.
- Produces: bootable `:humanizer_demo` OTP application, `HumanizerDemoWeb.Endpoint`, and `GET /health` returning `200 text/plain` with `ok\n`.

- [ ] **Step 1: Install and use the current Phoenix generator**

Run:

```bash
mix archive.install hex phx_new 1.8.9 --force
mix phx.new demo --app humanizer_demo --module HumanizerDemo --no-ecto --no-mailer --no-dashboard --no-gettext --no-install
```

Expected: Phoenix creates a database-free application; no dependency download is attempted by the second command.

- [ ] **Step 2: Point the demo at the root library and remove unused generated features**

Add the path dependency in `demo/mix.exs`:

```elixir
{:humanizer, path: ".."}
```

Keep Phoenix, LiveView, Bandit, esbuild, and Tailwind dependencies generated by Phoenix 1.8.9. Remove generated home-page controller/templates/tests because `/` will be a LiveView. Ensure no Ecto, Swoosh, gettext, dashboard, or telemetry-metrics dependency remains.

- [ ] **Step 3: Fetch and compile dependencies**

Run:

```bash
mix deps.get
mix compile --warnings-as-errors
```

Working directory: `demo/`.

Expected: dependencies resolve and the generated project compiles.

- [ ] **Step 4: Write the failing health test**

```elixir
defmodule HumanizerDemoWeb.HealthControllerTest do
  use HumanizerDemoWeb.ConnCase, async: true

  test "GET /health returns a plain readiness response", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert response(conn, 200) == "ok\n"
    assert get_resp_header(conn, "content-type") == ["text/plain; charset=utf-8"]
  end
end
```

- [ ] **Step 5: Run the health test and verify failure**

Run: `mix test test/humanizer_demo_web/controllers/health_controller_test.exs`

Expected: FAIL because `/health` has no route.

- [ ] **Step 6: Implement the health route and controller**

```elixir
defmodule HumanizerDemoWeb.HealthController do
  use HumanizerDemoWeb, :controller

  def show(conn, _params), do: text(conn, "ok\n")
end
```

Add `get "/health", HealthController, :show` to a route scope that does not require a LiveView session.

- [ ] **Step 7: Verify the baseline app**

Run:

```bash
mix test test/humanizer_demo_web/controllers/health_controller_test.exs
mix format --check-formatted
```

Expected: PASS. Do not commit yet.

---

### Task 2: Define the Pure Playground Contract, Catalog, Parser, and Code Renderer

**Files:**
- Create: `demo/lib/humanizer_demo/playground.ex`
- Create: `demo/lib/humanizer_demo/playground/catalog.ex`
- Create: `demo/lib/humanizer_demo/playground/parser.ex`
- Create: `demo/lib/humanizer_demo/playground/code.ex`
- Create: `demo/test/humanizer_demo/playground_test.exs`

**Interfaces:**
- Consumes: raw browser maps with string keys and values.
- Produces: `HumanizerDemo.Playground.ids/0`, `initial_state/0`, `evaluate/3`, `preset/3`, and `use_current_time/2`.
- Result shape: `%{id: atom(), params: map(), output: String.t() | nil, code: String.t() | nil, errors: %{optional(String.t()) => String.t()}}`.

- [ ] **Step 1: Write failing contract tests**

```elixir
defmodule HumanizerDemo.PlaygroundTest do
  use ExUnit.Case, async: true

  alias HumanizerDemo.Playground

  test "catalog exposes every public formatter in editorial order" do
    assert Playground.ids() == [
             :bytes,
             :number,
             :percentage,
             :delimit,
             :ordinal,
             :duration,
             :relative_time,
             :truncate,
             :list_join
           ]
  end

  test "catalog contains complete defaults and named presets" do
    for id <- Playground.ids() do
      assert is_map(HumanizerDemo.Playground.Catalog.default_params(id))

      assert [%{id: preset_id, label: label, params: params} | _] =
               HumanizerDemo.Playground.Catalog.presets(id)

      assert is_binary(preset_id) and is_binary(label) and is_map(params)
    end
  end

  test "parsers consume the complete value and code rendering escapes strings" do
    assert {:ok, 42} =
             HumanizerDemo.Playground.Parser.parse_integer(%{"value" => "42"}, "value")

    assert {:error, {"value", "Enter a whole number."}} =
             HumanizerDemo.Playground.Parser.parse_integer(%{"value" => "42px"}, "value")

    assert HumanizerDemo.Playground.Code.call("truncate", ["say \"hi\"", 8], omission: "…") ==
             ~s(Humanizer.truncate("say \\"hi\\"", 8, omission: "…"))
  end
end
```

- [ ] **Step 2: Run the contract tests and verify failure**

Run: `mix test test/humanizer_demo/playground_test.exs`

Expected: FAIL because `HumanizerDemo.Playground` does not exist.

- [ ] **Step 3: Implement the result lifecycle**

Define:

```elixir
@type formatter_id ::
        :bytes | :number | :percentage | :delimit | :ordinal | :duration |
          :relative_time | :truncate | :list_join

@type result :: %{
        id: formatter_id(),
        params: %{String.t() => String.t()},
        output: String.t() | nil,
        code: String.t() | nil,
        errors: %{optional(String.t()) => String.t()}
      }

@spec ids() :: [formatter_id()]
@spec initial_state() :: %{required(formatter_id()) => result()}
@spec evaluate(formatter_id(), map(), result() | nil) :: result()
def evaluate(id, params, previous \\ nil)
@spec preset(formatter_id(), String.t(), result() | nil) :: result()
@spec use_current_time(result(), DateTime.t()) :: result()
```

`evaluate/3` delegates parsing and Humanizer invocation to `Evaluator`. On `{:error, errors}`, keep the previous `output` and `code`, store the new raw params, and replace `errors`. On success, replace output/code and clear errors.

- [ ] **Step 4: Implement catalog defaults and named presets**

`Catalog.ids/0` returns the exact order in the test. `Catalog.default_params/1` returns complete string-key maps. `Catalog.presets/1` returns `%{id: string, label: string, params: map}` entries covering every preset listed in the design specification. `Catalog.preset!/2` fetches by stable string id and raises only for programmer-supplied unknown ids.

- [ ] **Step 5: Implement safe parsers**

Expose these exact parser functions:

```elixir
parse_integer(params, key, opts \\ [])
parse_number(params, key, opts \\ [])
parse_precision(params, key \\ "precision", opts \\ [])
parse_enum(params, key, allowed)
parse_datetime(params, key)
parse_optional_positive_integer(params, key)
parse_lines(params, key)
```

Use `Integer.parse/1`, `Float.parse/1`, and `NaiveDateTime.from_iso8601/1`; require complete-string consumption. Convert `datetime-local` values to UTC with `DateTime.from_naive!(naive, "Etc/UTC")`. Return `{:ok, value}` or `{:error, {key, exact_message}}`; do not raise for user data.

- [ ] **Step 6: Implement deterministic code rendering**

Expose `Code.call/3`:

```elixir
@spec call(String.t(), [term()], keyword()) :: String.t()
def call(function, args, opts) do
  rendered = Enum.map_join(args, ", ", &inspect/1)
  rendered_opts = Enum.map_join(opts, ", ", fn {key, value} -> "#{key}: #{inspect(value)}" end)
  separator = if rendered != "" and rendered_opts != "", do: ", ", else: ""
  "Humanizer.#{function}(#{rendered}#{separator}#{rendered_opts})"
end
```

Datetime arguments pass through `inspect/1`, which renders UTC values as `~U[...]` literals. String/list values also pass through `inspect/1` so quotes and newlines are escaped.

- [ ] **Step 7: Run contract tests**

Run: `mix test test/humanizer_demo/playground_test.exs`

Expected: catalog, parser, and code-rendering tests pass. Do not commit.

---

### Task 3: Implement Size and Number Evaluators Test-First

**Files:**
- Create: `demo/lib/humanizer_demo/playground/evaluator.ex`
- Modify: `demo/test/humanizer_demo/playground_test.exs`

**Interfaces:**
- Consumes: `Evaluator.evaluate/2` with `:bytes`, `:number`, `:percentage`, `:delimit`, or `:ordinal` and raw params.
- Produces: `{:ok, %{output: String.t(), code: String.t()}}` or `{:error, error_map}`.

- [ ] **Step 1: Add table-driven numeric formatter tests**

```elixir
describe "size and numeric formatters" do
  test "bytes supports systems, precision, and carry presets" do
    assert %{output: "2.5 MB", code: "Humanizer.bytes(2456789, system: :decimal, precision: 1)"} =
             Playground.evaluate(:bytes, %{"value" => "2456789", "system" => "decimal", "precision" => "1"})

    assert Playground.evaluate(:bytes, %{"value" => "2456789", "system" => "binary", "precision" => "2"}).output == "2.34 MiB"
    assert Playground.evaluate(:bytes, %{"value" => "999950", "system" => "decimal", "precision" => "1"}).output == "1.0 MB"
  end

  test "number and percentage expose precision and signed input" do
    assert Playground.evaluate(:number, %{"value" => "-1234", "precision" => "2"}).output == "-1.23K"
    assert Playground.evaluate(:percentage, %{"value" => "1", "precision" => "1"}).output == "100.0%"
    assert Playground.evaluate(:percentage, %{"value" => "-0.125", "precision" => "0"}).output == "-13%"
  end

  test "delimit supports natural precision and a custom separator" do
    assert Playground.evaluate(:delimit, %{"value" => "1234.5", "separator" => " ", "precision_mode" => "natural", "precision" => "2"}).output == "1 234.5"
    assert Playground.evaluate(:delimit, %{"value" => "1234.5", "separator" => ",", "precision_mode" => "fixed", "precision" => "2"}).output == "1,234.50"
  end

  test "ordinal demonstrates English suffix exceptions" do
    for {value, expected} <- [{"1", "1st"}, {"11", "11th"}, {"23", "23rd"}, {"-1", "-1st"}] do
      assert Playground.evaluate(:ordinal, %{"value" => value}).output == expected
    end
  end

  test "invalid input preserves the last valid output" do
    valid =
      Playground.evaluate(:bytes, %{
        "value" => "1000",
        "system" => "decimal",
        "precision" => "1"
      })

    invalid = Playground.evaluate(:bytes, %{valid.params | "value" => "-1"}, valid)
    assert invalid.output == "1.0 KB"
    assert invalid.errors == %{"value" => "Enter a non-negative whole number."}
  end
end
```

- [ ] **Step 2: Run the numeric tests and verify failure**

Run: `mix test test/humanizer_demo/playground_test.exs --only numeric`

Expected: FAIL because evaluator clauses are missing. Add `@tag :numeric` to the describe block before using the command.

- [ ] **Step 3: Implement explicit evaluator clauses**

Each clause parses the documented values, builds only supported keyword options, calls the corresponding `Humanizer` public function, and renders the matching code. Required calls are:

```elixir
Humanizer.bytes(value, system: system, precision: precision)
Humanizer.number(value, precision: precision)
Humanizer.percentage(value, precision: precision)
Humanizer.delimit(value, delimit_options)
Humanizer.ordinal(value)
```

For natural delimit precision, omit `:precision` from both the function call and displayed snippet. Reject negative bytes, negative precision, empty separators, and non-integer ordinal values with the exact messages asserted by tests.

- [ ] **Step 4: Add validation assertions**

Cover `"abc"`, partial numeric strings such as `"12px"`, negative byte values, negative precision, and empty separator. Assert exact field-keyed maps, including `%{"value" => "Enter a number."}` and `%{"precision" => "Enter zero or a positive whole number."}`.

- [ ] **Step 5: Run all numeric tests**

Run: `mix test test/humanizer_demo/playground_test.exs`

Expected: every size/numeric test passes. Do not commit.

---

### Task 4: Implement Time, Text, and List Evaluators Test-First

**Files:**
- Modify: `demo/lib/humanizer_demo/playground/evaluator.ex`
- Modify: `demo/test/humanizer_demo/playground_test.exs`

**Interfaces:**
- Consumes: `Evaluator.evaluate/2` with `:duration`, `:relative_time`, `:truncate`, or `:list_join` and raw params.
- Produces: the same success/error tuples as Task 3.

- [ ] **Step 1: Add time/text/list behavior tests**

```elixir
describe "time, text, and list formatters" do
  test "initial state contains a valid output and code for every formatter" do
    state = Playground.initial_state()
    assert Enum.sort(Map.keys(state)) == Enum.sort(Playground.ids())
    assert Enum.all?(state, fn {_id, card} -> card.output && card.code && card.errors == %{} end)
  end

  test "duration exposes units and long/short formats" do
    assert Playground.evaluate(:duration, %{"value" => "3725", "units" => "2", "format" => "long"}).output == "1 hour, 2 minutes"
    assert Playground.evaluate(:duration, %{"value" => "3725", "units" => "all", "format" => "short"}).output == "1h 2m 5s"
    assert Playground.evaluate(:duration, %{"value" => "0.5", "units" => "2", "format" => "short"}).output == "<1s"
  end

  test "relative time uses explicit UTC value and reference" do
    params = %{"value" => "2026-05-13T10:00", "reference" => "2026-05-15T10:00", "format" => "long"}
    assert Playground.evaluate(:relative_time, params).output == "2 days ago"
    assert Playground.evaluate(:relative_time, %{params | "value" => "2026-05-15T13:00"}).output == "in 3 hours"
  end

  test "truncate is Unicode-safe and supports word breaks" do
    assert Playground.evaluate(:truncate, %{"text" => "héllo wörld", "length" => "6", "omission" => "…", "break" => "char"}).output == "héllo…"
    assert Playground.evaluate(:truncate, %{"text" => "the quick brown fox", "length" => "9", "omission" => "…", "break" => "word"}).output == "the…"
  end

  test "list join exposes all documented options" do
    params = %{"items" => "Alice\nBob\nCharlie", "conjunction" => "and", "oxford" => "true", "max_enabled" => "false", "max" => "2", "other" => "other", "others" => "others"}
    assert Playground.evaluate(:list_join, params).output == "Alice, Bob, and Charlie"
    assert Playground.evaluate(:list_join, %{params | "max_enabled" => "true", "max" => "2"}).output == "Alice, Bob, and 1 other"
  end
end
```

- [ ] **Step 2: Run the new tests and verify failure**

Run: `mix test test/humanizer_demo/playground_test.exs`

Expected: FAIL on the four missing evaluator categories.

- [ ] **Step 3: Implement duration and relative-time clauses**

Map `"all"` to `:all`, positive unit strings to integers, and format strings to atoms from a fixed allowlist. Parse UTC `datetime-local` fields. Required calls:

```elixir
Humanizer.duration(value, units: units, format: format)
Humanizer.relative_time(value_datetime, reference_datetime, format: format)
```

`Playground.use_current_time/2` formats the supplied UTC `DateTime` as minute-resolution `YYYY-MM-DDTHH:MM`, updates `"reference"`, and re-evaluates deterministically.

- [ ] **Step 4: Implement truncate and list clauses**

Required calls:

```elixir
Humanizer.truncate(text, length, omission: omission, break: break_mode)
Humanizer.list_join(items, list_options)
```

Split list items on line endings, remove only blank lines, and preserve whitespace inside nonblank items. Include `:max`, `:other`, and `:others` only when max is enabled; always include the user-visible conjunction and Oxford setting in the displayed call.

- [ ] **Step 5: Add invalid-input and safe-code tests**

Assert errors for negative duration, invalid dates, negative truncate length, enabled max less than one, and unknown enum values. Add strings containing quotes and newlines and assert the generated call contains escaped literals rather than executable interpolation.

- [ ] **Step 6: Run the complete pure suite**

Run:

```bash
mix test test/humanizer_demo/playground_test.exs
mix format --check-formatted
```

Expected: all pure playground tests pass. Do not commit.

---

### Task 5: Build the LiveView Interaction Layer

**Files:**
- Create: `demo/lib/humanizer_demo_web/live/playground_live.ex`
- Create: `demo/lib/humanizer_demo_web/live/playground_live.html.heex`
- Create: `demo/lib/humanizer_demo_web/components/playground_components.ex`
- Modify: `demo/lib/humanizer_demo_web/router.ex`
- Create: `demo/test/humanizer_demo_web/live/playground_live_test.exs`

**Interfaces:**
- Consumes: `Playground.initial_state/0`, `evaluate/3`, `preset/3`, and `use_current_time/2`.
- Produces: public LiveView route `/` with stable card ids `formatter-{id}`, forms `form-{id}`, results `result-{id}`, code nodes `code-{id}`, and field error ids `{id}-{field}-error`.

- [ ] **Step 1: Write failing initial-render and interaction tests**

```elixir
defmodule HumanizerDemoWeb.PlaygroundLiveTest do
  use HumanizerDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "renders the showcase and every formatter", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "Raw values in. Clear language out."

    for id <- HumanizerDemo.Playground.ids() do
      assert has_element?(view, "#formatter-#{id}")
      assert has_element?(view, "#result-#{id}")
      assert has_element?(view, "#code-#{id}")
    end
  end

  test "one card changes without replacing another card result", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    duration_before = element(view, "#result-duration") |> render()

    view
    |> form("#form-bytes", %{"formatter" => "bytes", "params" => %{"value" => "1024", "system" => "binary", "precision" => "1"}})
    |> render_change()

    assert has_element?(view, "#result-bytes", "1.0 KiB")
    assert element(view, "#result-duration") |> render() == duration_before
  end

  test "invalid input is local and presets restore a valid result", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    view |> form("#form-bytes", %{"formatter" => "bytes", "params" => %{"value" => "-1", "system" => "decimal", "precision" => "1"}}) |> render_change()
    assert has_element?(view, "#bytes-value-error", "Enter a non-negative whole number.")

    view |> element("#formatter-bytes [data-preset='zero']") |> render_click()
    assert has_element?(view, "#result-bytes", "0 B")
    refute has_element?(view, "#bytes-value-error")
  end
end
```

- [ ] **Step 2: Run the LiveView tests and verify failure**

Run: `mix test test/humanizer_demo_web/live/playground_live_test.exs`

Expected: FAIL because `/` is not a LiveView and the modules do not exist.

- [ ] **Step 3: Implement LiveView state and exact events**

`mount/3` assigns `cards: Playground.initial_state()` and `catalog: Catalog.entries()`. Implement only these events:

```elixir
handle_event("change", %{"formatter" => id, "params" => params}, socket)
handle_event("preset", %{"formatter" => id, "preset" => preset}, socket)
handle_event("use-current-time", %{"formatter" => "relative_time"}, socket)
```

Convert ids with a fixed string-to-existing-atom map; never call `String.to_atom/1` on browser data. Replace only the selected key in `socket.assigns.cards`.

- [ ] **Step 4: Implement shared and explicit formatter components**

Create `formatter_card/1`, `field_error/1`, `result_panel/1`, `code_panel/1`, and `preset_row/1`. Create explicit control functions `bytes_controls/1`, `number_controls/1`, `percentage_controls/1`, `delimit_controls/1`, `ordinal_controls/1`, `duration_controls/1`, `relative_time_controls/1`, `truncate_controls/1`, and `list_join_controls/1`. Every input receives a visible `<label for>` and `aria-describedby` when an error exists.

- [ ] **Step 5: Compose all chapters and route `/`**

The HEEx template contains navigation, hero, four section headings, nine stable cards, and closing constraints. Add `live "/", PlaygroundLive` under the browser pipeline. Remove the generated home controller route.

- [ ] **Step 6: Add tests for every event family**

Use one representative `render_change/2` or `render_click/1` per formatter. Assert `relative_time` current-time action changes the reference field, list presets update all related fields, advanced `<details>` controls are present, every error node uses `role="alert"`, and each copy button points at the matching code id.

- [ ] **Step 7: Run LiveView and full demo tests**

Run:

```bash
mix test test/humanizer_demo_web/live/playground_live_test.exs
mix test
```

Expected: PASS. Do not commit.

---

### Task 6: Apply the Editorial Lab Visual System and Clipboard Interaction

**Files:**
- Modify: `demo/lib/humanizer_demo_web/components/layouts.ex`
- Modify: `demo/lib/humanizer_demo_web/components/layouts/root.html.heex`
- Modify: `demo/lib/humanizer_demo_web/live/playground_live.html.heex`
- Modify: `demo/lib/humanizer_demo_web/components/playground_components.ex`
- Modify: `demo/assets/css/app.css`
- Modify: `demo/assets/js/app.js`
- Create: `demo/priv/static/favicon.svg`
- Modify: `demo/test/humanizer_demo_web/live/playground_live_test.exs`

**Interfaces:**
- Consumes: stable DOM ids from Task 5.
- Produces: responsive Editorial Lab UI and `Hooks.CopyCode` clipboard hook with `data-copy-target`.

- [ ] **Step 1: Add structural accessibility assertions**

Add tests asserting one `h1`, ordered chapter `h2` elements, nine card `h3` elements, visible labels for every editable control, a skip link targeting `#main-content`, installation/code copy buttons with accessible names, and no controls missing a `type` attribute.

- [ ] **Step 2: Run the structural tests and verify failure**

Run: `mix test test/humanizer_demo_web/live/playground_live_test.exs`

Expected: FAIL on missing final document structure and controls.

- [ ] **Step 3: Implement the page shell and real copy**

Use these primary content strings exactly:

```text
Human-friendly formatting for Elixir
Raw values in. Clear language out.
Nine focused helpers. Zero configuration. Every example is live.
Size
Numbers
Time
Text & Lists
Small functions. Noticeably better interfaces.
```

Add package installation, GitHub, and HexDocs links from the root project metadata. Include truthful constraint copy from the root README and no fabricated metrics.

- [ ] **Step 4: Implement the responsive CSS system**

Define project-prefixed custom properties for paper, ink, muted ink, panel, line, lime, warning, and error colors in `:root`, with complete overrides under `@media (prefers-color-scheme: dark)`. Implement:

- a centered editorial page with fluid inline padding;
- a sticky translucent top bar;
- a two-column hero above 900px and one-column hero below it;
- a 12-column bento grid where cards span 4, 6, 8, or 12 columns intentionally;
- a single-column card stack below 720px;
- minimum 44px interactive targets;
- visible `:focus-visible` rings;
- no horizontal overflow at 320px; and
- reduced transitions under `prefers-reduced-motion: reduce`.

Use system sans-serif, editorial serif, and monospace stacks so production has no font CDN dependency.

- [ ] **Step 5: Implement clipboard behavior**

Register `Hooks.CopyCode` in `app.js`. On click, find the element id in `data-copy-target`, call `navigator.clipboard.writeText(target.textContent)`, set button text to `Copied` for 1.5 seconds, and restore the original accessible label. Catch clipboard rejection and set `Copy failed` without throwing.

- [ ] **Step 6: Render and inspect the application visually**

Run `mix phx.server` in `demo/`, open `/`, and inspect at desktop, 736px, and 320px in light and dark system appearances. Exercise every card, advanced disclosure, preset, copy button, focus order, and inline error. Fix any overlap, truncation, low contrast, missing state, or console error found.

- [ ] **Step 7: Run assets and tests**

Run:

```bash
mix assets.deploy
mix test
mix format --check-formatted
```

Expected: assets build and all tests pass. Do not commit.

---

### Task 7: Add Production Runtime, Release, Docker, and Documentation

**Files:**
- Modify: `demo/config/runtime.exs`
- Modify: `demo/mix.exs`
- Create: `demo/Dockerfile`
- Create: `demo/Dockerfile.dockerignore`
- Create: `demo/README.md`
- Modify: `README.md`
- Modify: `demo/test/humanizer_demo_web/controllers/health_controller_test.exs`

**Interfaces:**
- Consumes: Phoenix endpoint and `/health` from Task 1.
- Produces: `_build/prod/rel/humanizer_demo/bin/humanizer_demo`, a root-context Docker build, and reproducible operator docs.

- [ ] **Step 1: Add a runtime configuration test boundary**

Keep test configuration independent of production environment variables. Add a test that `/health` contains no session cookie and succeeds with the browser-independent route. Assert `get_resp_header(conn, "set-cookie") == []`.

- [ ] **Step 2: Implement production runtime validation**

In `runtime.exs`, when `config_env() == :prod`, fetch `SECRET_KEY_BASE`, read `PHX_HOST` with default `"example.com"`, parse `PORT` with default `"4000"`, and enable the endpoint when `PHX_SERVER` is present. Fail with an explicit message when the secret is missing or the port is not an integer.

- [ ] **Step 3: Add release aliases and verify a release**

Keep the generated `assets.deploy` alias. Run:

```bash
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite
```

Expected: `_build/prod/rel/humanizer_demo/` is created without database tasks.

- [ ] **Step 4: Generate and adapt the multi-stage Dockerfile**

Run `mix phx.gen.release --docker` in `demo/` to obtain Phoenix 1.8.9's pinned Elixir/OTP and Debian image tags, then adapt the generated file for repository-root context. Invoke it with `docker build -f demo/Dockerfile -t humanizer-demo .`. Copy root `mix.exs`, `mix.lock`, `lib/`, and required package metadata before copying the demo project so the path dependency compiles. Build assets and release in the builder. In the final stage create `humanizer` user/group, copy only the release, set `PHX_SERVER=true`, expose `4000`, add an HTTP `/health` healthcheck, switch to `USER humanizer`, and start `bin/humanizer_demo start`.

- [ ] **Step 5: Add narrow Dockerfile-specific ignore rules**

In `demo/Dockerfile.dockerignore`, exclude root and demo `_build`, `deps`, `.git`, `.superpowers`, docs build output, coverage, and local archives. Do not exclude root `lib`, root `mix.exs`, root `mix.lock`, `demo/config`, `demo/lib`, `demo/assets`, or `demo/priv`.

- [ ] **Step 6: Write exact operator documentation**

Document these commands in `demo/README.md`:

```bash
cd demo
mix deps.get
mix phx.server
mix test
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite
docker build -f demo/Dockerfile -t humanizer-demo .
docker run --rm -p 4000:4000 -e PHX_HOST=localhost -e SECRET_KEY_BASE="$(mix phx.gen.secret)" humanizer-demo
```

Explain `PHX_SERVER`, `PHX_HOST`, `PORT`, and `SECRET_KEY_BASE`. Add a concise root README section linking to `demo/` and stating it is excluded from Hex packaging.

- [ ] **Step 7: Verify release, health, and documentation commands**

Build the release, start it with explicit environment variables, request `/health`, and stop it cleanly. Build the Docker image and run its health probe if Docker is available. If Docker is unavailable, validate the Dockerfile syntax and document the exact unavailable command in the final verification report without claiming it passed.

Expected: release responds `ok`; container, when available, becomes healthy as a non-root process. Do not commit.

---

### Task 8: Extend CI and Prove Hex Exclusion

**Files:**
- Modify: `.github/workflows/ci.yml`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: root and demo Mix projects.
- Produces: preserved root matrix plus deterministic demo and packaging jobs.

- [ ] **Step 1: Add `.superpowers/` to root ignore rules**

Add:

```gitignore
/.superpowers/
```

Do not alter the user's `.tool-versions` file.

- [ ] **Step 2: Add a demo CI job**

On Elixir 1.18 / OTP 27, cache `demo/deps` and `demo/_build`, run from `demo/`:

```bash
mix deps.get
mix compile --warnings-as-errors
mix format --check-formatted
mix test
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite
```

Provide a deterministic CI `SECRET_KEY_BASE` only to production build steps.

- [ ] **Step 3: Add Hex archive verification**

In the root lint job, run `mix hex.build`, list the resulting tar contents using `mix hex.build --unpack` into a temporary directory, and fail if any path begins with `demo/`. Keep the assertion in readable shell with an explicit success message.

- [ ] **Step 4: Add Docker build validation**

Run `docker build -f demo/Dockerfile -t humanizer-demo:test .` from the repository root after the demo test job. The build must not push or publish the image.

- [ ] **Step 5: Validate workflow and local package contents**

Run:

```bash
mix hex.build
mix hex.build --unpack
```

Inspect the unpacked package and assert that no `demo/` path exists. Remove only the generated package archive/unpack directory after recording the result; these outputs are reproducible and ignored.

Expected: library packaging succeeds and excludes the demo. Do not commit.

---

### Task 9: Full Verification and Single Final Commit

**Files:**
- Verify: all root, docs, CI, and `demo/` files created or modified above.
- Preserve unstaged: `.tool-versions`.

**Interfaces:**
- Consumes: complete implementation.
- Produces: one verified commit containing the design, plan, demo, documentation, and CI changes but not the user's `.tool-versions` change or `.superpowers/` output.

- [ ] **Step 1: Run root verification**

Run from the repository root:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
mix credo --strict
mix hex.build
```

Expected: every command exits zero.

- [ ] **Step 2: Run demo verification**

Run from `demo/`:

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite
```

Expected: every command exits zero.

- [ ] **Step 3: Run delivery smoke tests**

Start the production release with explicit environment values, confirm `/health`, then stop it. Run `docker build -f demo/Dockerfile -t humanizer-demo:test .` and its healthcheck when Docker is locally available.

- [ ] **Step 4: Inspect the final working tree**

Run:

```bash
git status --short
git diff --check
git diff -- . ':(exclude).tool-versions'
```

Confirm `.tool-versions` remains modified but unstaged, `.superpowers/` is ignored, no generated `_build`, `deps`, release, package tar, or unpack directory is staged, and every requested source/doc file is present.

- [ ] **Step 5: Stage only project deliverables**

Run:

```bash
git add .gitignore .github/workflows/ci.yml README.md docs/superpowers demo
git diff --cached --check
git status --short
```

Confirm `.tool-versions` is not staged.

- [ ] **Step 6: Create the single final commit**

Run:

```bash
git commit -m "Add interactive Phoenix LiveView demo"
```

Expected: one commit contains the ready project and supporting documents; no earlier implementation commits exist.
