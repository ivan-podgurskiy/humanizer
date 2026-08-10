defmodule HumanizerDemoWeb.PlaygroundLiveTest do
  use HumanizerDemoWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "output panels use the theme-stable code surface" do
    css = File.read!(Path.expand("../../../assets/css/app.css", __DIR__))

    assert css =~
             ~r/\.result-panel\s*\{[^}]*background:\s*var\(--code\);/s
  end

  test "renders the showcase and every formatter", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert has_element?(view, "h1#hero-title", "Raw values in. Clear language out.")

    for id <- HumanizerDemo.Playground.ids() do
      assert has_element?(view, "#formatter-#{id}")
      assert has_element?(view, "#form-#{id}")
      assert has_element?(view, "#result-#{id}")
      assert has_element?(view, "#code-#{id}")
    end
  end

  test "describes zero global configuration with a single zero", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert view
           |> element(".principles div:nth-child(2) strong")
           |> render() == "<strong>0</strong>"
  end

  test "one card changes without replacing another card result", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    duration_before = view |> element("#result-duration") |> render()

    view
    |> form("#form-bytes", %{
      "formatter" => "bytes",
      "params" => %{"value" => "1024", "system" => "binary", "precision" => "1"}
    })
    |> render_change()

    assert has_element?(view, "#result-bytes", "1.0 KiB")
    assert view |> element("#result-duration") |> render() == duration_before
  end

  test "invalid input is local and a preset restores a valid result", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#form-bytes", %{
      "formatter" => "bytes",
      "params" => %{"value" => "-1", "system" => "decimal", "precision" => "1"}
    })
    |> render_change()

    assert has_element?(view, "#bytes-value-error", "Enter a non-negative whole number.")
    assert has_element?(view, "#result-bytes", "2.5 MB")

    view
    |> element("#formatter-bytes [data-preset='zero']")
    |> render_click()

    assert has_element?(view, "#result-bytes", "0 B")
    refute has_element?(view, "#bytes-value-error")
  end

  test "hero validation is local and associated with its input", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#hero-bytes-form", %{
      "formatter" => "bytes",
      "params" => %{"value" => "-1", "system" => "decimal", "precision" => "1"}
    })
    |> render_change()

    assert has_element?(
             view,
             "#hero-bytes-value[aria-invalid='true'][aria-describedby='hero-bytes-value-error']"
           )

    assert has_element?(view, "#hero-bytes-value-error", "Enter a non-negative whole number.")
  end

  test "malformed and stale events do not disconnect the LiveView", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    assert render_hook(view, "change", %{"formatter" => "unknown", "params" => %{}}) =~
             "Raw values in."

    assert render_hook(view, "change", %{}) =~ "Raw values in."

    assert render_hook(view, "change", %{"formatter" => "bytes", "params" => "invalid"}) =~
             "Raw values in."

    assert render_click(view, "preset", %{"formatter" => "bytes", "preset" => "unknown"}) =~
             "Raw values in."

    assert has_element?(view, "#result-bytes", "2.5 MB")
  end

  test "time, text, and list cards update through their real controls", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("#form-duration", %{
      "formatter" => "duration",
      "params" => %{"value" => "45", "units" => "all", "format" => "short"}
    })
    |> render_change()

    assert has_element?(view, "#result-duration", "45s")

    view
    |> form("#form-truncate", %{
      "formatter" => "truncate",
      "params" => %{
        "text" => "the quick brown fox",
        "length" => "9",
        "omission" => "…",
        "break" => "word"
      }
    })
    |> render_change()

    assert has_element?(view, "#result-truncate", "the…")

    view
    |> element("#formatter-list_join [data-preset='collapsed']")
    |> render_click()

    assert has_element?(view, "#result-list_join", "Alice, Bob and 3 others")
  end

  test "relative time can set the reference to current UTC time", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    before = view |> element("#relative_time-reference") |> render()

    view
    |> element("#formatter-relative_time [data-action='use-current-time']")
    |> render_click()

    after_click = view |> element("#relative_time-reference") |> render()
    refute after_click == before
  end

  test "remaining number cards update and advanced options use native disclosure", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    changes = [
      {:number, %{"value" => "1000", "precision" => "1"}, "1.0K"},
      {:percentage, %{"value" => "1", "precision" => "1"}, "100.0%"},
      {:delimit,
       %{
         "value" => "1234.5",
         "separator" => " ",
         "precision_mode" => "fixed",
         "precision" => "2"
       }, "1 234.50"},
      {:ordinal, %{"value" => "11"}, "11th"},
      {:relative_time,
       %{
         "value" => "2026-05-15T13:00",
         "reference" => "2026-05-15T10:00",
         "format" => "short"
       }, "in 3h"}
    ]

    for {id, params, expected} <- changes do
      view
      |> form("#form-#{id}", %{"formatter" => Atom.to_string(id), "params" => params})
      |> render_change()

      assert has_element?(view, "#result-#{id}", expected)
    end

    assert has_element?(view, "#formatter-delimit details")
    assert has_element?(view, "#formatter-list_join details")
  end

  test "uses a semantic, keyboard-friendly Editorial Lab document structure", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert has_element?(view, "a.skip-link[href='#main-content']", "Skip to playground")
    assert has_element?(view, "nav[aria-label='Primary navigation']")
    assert html =~ ~s(href="/assets/js/app.css")
    assert has_element?(view, "h1#hero-title", "Raw values in. Clear language out.")
    assert has_element?(view, "#hero-bytes-form")
    assert has_element?(view, "#install-snippet", ~s({:humanizer, "~> 0.3.0"}))

    for heading <- ["Size", "Numbers", "Time", "Text & Lists"] do
      assert has_element?(view, "h2", heading)
    end

    for id <- HumanizerDemo.Playground.ids() do
      assert has_element?(view, "#formatter-#{id} h3")
      assert has_element?(view, "#copy-#{id}[phx-hook='CopyCode'][type='button']")
    end

    assert has_element?(view, "label[for='bytes-value']", "Byte count")
    assert has_element?(view, "label[for='relative_time-reference']", "Reference (UTC)")
    assert has_element?(view, "label[for='list_join-items']", "Items — one per line")
    refute has_element?(view, "button:not([type])")
  end
end
