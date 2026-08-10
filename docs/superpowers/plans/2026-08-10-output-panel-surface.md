# Stable Output Panel Surface Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep every formatter Output panel near-black in both system themes while retaining lime formatted values.

**Architecture:** Reuse the existing theme-stable `--code` surface token instead of the semantic `--ink` token, which intentionally flips from dark to light between themes. Protect the visual contract with one focused structural test and verify the rendered result at 320px in the running LiveView.

**Tech Stack:** Phoenix LiveView 1.2, HEEx, project CSS, ExUnit, in-app browser QA.

## Global Constraints

- Change only the Output panel surface; preserve the rest of the Editorial Lab palette and layout.
- Keep `--lime` as the formatted-value color and the existing light-red error color.
- Maintain at least 44px interactive targets and no horizontal overflow at 320 CSS pixels.
- Do not create a separate specification or plan commit; commit documentation together with the finished CSS change.
- Preserve `.tool-versions` unstaged.

---

### Task 1: Make Output Panels Theme-Stable

**Files:**
- Modify: `demo/test/humanizer_demo_web/live/playground_live_test.exs`
- Modify: `demo/assets/css/app.css`
- Modify: `docs/superpowers/specs/2026-08-10-humanizer-liveview-demo-design.md`
- Create: `docs/superpowers/plans/2026-08-10-output-panel-surface.md`

**Interfaces:**
- Consumes: the existing `--code`, `--lime`, `.result-panel`, and `.result-panel__value` CSS contracts.
- Produces: a `.result-panel` whose computed background remains near-black in light and dark system themes.

- [ ] **Step 1: Add a failing structural regression test**

Add this test to `PlaygroundLiveTest`:

```elixir
test "output panels use the theme-stable code surface" do
  css = File.read!(Path.expand("../../../assets/css/app.css", __DIR__))

  assert css =~
           ~r/\.result-panel\s*\{[^}]*background:\s*var\(--code\);/s
end
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run:

```sh
cd demo
mix test test/humanizer_demo_web/live/playground_live_test.exs
```

Expected: FAIL because `.result-panel` currently uses `background: var(--ink)`.

- [ ] **Step 3: Apply the minimal CSS change**

In `demo/assets/css/app.css`, change only the surface declaration:

```css
.result-panel {
  /* existing declarations remain unchanged */
  background: var(--code);
  color: var(--code-ink);
}
```

Keep `.result-panel__value { color: var(--lime); }` and `.result-panel .field-error { color: #ffadb5; }` unchanged.

- [ ] **Step 4: Run automated verification**

Run:

```sh
cd demo
mix format --check-formatted
mix test
mix assets.deploy
```

Expected: formatting passes, all demo tests pass, and CSS/JS assets build successfully.

- [ ] **Step 5: Verify the running page visually**

At `http://localhost:4000/`, inspect an Output block in the current dark system theme and confirm:

- computed background is the near-black `--code` color;
- formatted output remains lime;
- no horizontal overflow exists at 320px;
- copy, preset, and current-time controls remain at least 44px high.

- [ ] **Step 6: Commit the finished change**

Stage only the CSS, regression test, specification, and this plan. Confirm `.tool-versions` is not staged, then create:

```sh
git commit -m "Refine output panel contrast"
```
