defmodule HumanizerDemo.PlaygroundTest do
  use ExUnit.Case, async: true

  alias HumanizerDemo.Playground
  alias HumanizerDemo.Playground.{Catalog, Code, Parser}

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
      assert is_map(Catalog.default_params(id))
      assert map_size(Catalog.default_params(id)) > 0

      assert [%{id: preset_id, label: label, params: params} | _] = Catalog.presets(id)
      assert is_binary(preset_id) and is_binary(label) and is_map(params)
      assert Catalog.preset!(id, preset_id).params == params
    end
  end

  describe "strict parsers" do
    test "integer parser consumes the entire input" do
      assert Parser.parse_integer(%{"value" => "42"}, "value") == {:ok, 42}

      assert Parser.parse_integer(%{"value" => "42px"}, "value") ==
               {:error, {"value", "Enter a whole number."}}
    end

    test "numeric parser distinguishes integers and floats" do
      assert Parser.parse_number(%{"value" => "42"}, "value") == {:ok, 42}
      assert Parser.parse_number(%{"value" => "42.5"}, "value") == {:ok, 42.5}

      assert Parser.parse_number(%{"value" => "4.2px"}, "value") ==
               {:error, {"value", "Enter a number."}}
    end

    test "precision and positive optional integers enforce their bounds" do
      assert Parser.parse_precision(%{"precision" => "0"}) == {:ok, 0}
      assert Parser.parse_precision(%{"precision" => "6"}) == {:ok, 6}

      assert Parser.parse_precision(%{"precision" => "-1"}) ==
               {:error, {"precision", "Enter zero or a positive whole number."}}

      assert Parser.parse_precision(%{"precision" => "999999999"}) ==
               {:error, {"precision", "Use a precision from 0 to 6."}}

      assert Parser.parse_optional_positive_integer(%{"max" => ""}, "max") == {:ok, nil}
      assert Parser.parse_optional_positive_integer(%{"max" => "2"}, "max") == {:ok, 2}

      assert Parser.parse_optional_positive_integer(%{"max" => "0"}, "max") ==
               {:error, {"max", "Enter a whole number greater than zero."}}
    end

    test "enum, datetime, and line parsers reject unknown or partial data" do
      assert Parser.parse_enum(%{"format" => "short"}, "format", %{
               "long" => :long,
               "short" => :short
             }) ==
               {:ok, :short}

      assert Parser.parse_enum(%{"format" => "tiny"}, "format", %{
               "long" => :long,
               "short" => :short
             }) ==
               {:error, {"format", "Choose a valid option."}}

      assert {:ok, ~U[2026-05-15 10:00:00Z]} =
               Parser.parse_datetime(%{"reference" => "2026-05-15T10:00"}, "reference")

      assert Parser.parse_datetime(%{"reference" => "not-a-date"}, "reference") ==
               {:error, {"reference", "Enter a valid UTC date and time."}}

      assert Parser.parse_lines(%{"items" => "Alice\n\n Bob \r\nCharlie"}, "items") ==
               {:ok, ["Alice", " Bob ", "Charlie"]}
    end
  end

  test "catalog includes every required boundary preset" do
    required = %{
      number: ~w(zero below-boundary boundary negative carry trillion),
      ordinal:
        ~w(zero first second third eleventh twelfth thirteenth twenty-first twenty-second twenty-third negative),
      truncate: ~w(unchanged character word custom omission-limit unicode)
    }

    for {id, expected_ids} <- required do
      preset_ids = Enum.map(Catalog.presets(id), & &1.id)
      assert Enum.all?(expected_ids, &(&1 in preset_ids))

      for preset_id <- expected_ids do
        result = Playground.preset(id, preset_id)
        assert is_binary(result.output)
        assert is_binary(result.code)
        assert result.errors == %{}
      end
    end
  end

  test "code rendering escapes strings and keeps keyword options explicit" do
    assert Code.call("truncate", ["say \"hi\"", 8], omission: "…") ==
             "Humanizer.truncate(\"say \\\"hi\\\"\", 8, omission: \"…\")"

    assert Code.call("bytes", [1024], system: :binary, precision: 1) ==
             "Humanizer.bytes(1024, system: :binary, precision: 1)"
  end

  describe "size and numeric formatters" do
    @describetag :numeric

    test "bytes supports systems, precision, and carry presets" do
      assert %{
               output: "2.5 MB",
               code: "Humanizer.bytes(2456789, system: :decimal, precision: 1)"
             } =
               Playground.evaluate(:bytes, %{
                 "value" => "2456789",
                 "system" => "decimal",
                 "precision" => "1"
               })

      assert Playground.evaluate(:bytes, %{
               "value" => "2456789",
               "system" => "binary",
               "precision" => "2"
             }).output == "2.34 MiB"

      assert Playground.evaluate(:bytes, %{
               "value" => "999950",
               "system" => "decimal",
               "precision" => "1"
             }).output == "1.0 MB"
    end

    test "number and percentage expose precision and signed input" do
      assert Playground.evaluate(:number, %{"value" => "-1234", "precision" => "2"}).output ==
               "-1.23K"

      assert Playground.evaluate(:percentage, %{"value" => "1", "precision" => "1"}).output ==
               "100.0%"

      assert Playground.evaluate(:percentage, %{"value" => "-0.125", "precision" => "0"}).output ==
               "-13%"
    end

    test "delimit supports natural precision and a custom separator" do
      assert Playground.evaluate(:delimit, %{
               "value" => "1234.5",
               "separator" => " ",
               "precision_mode" => "natural",
               "precision" => "2"
             }).output == "1 234.5"

      fixed =
        Playground.evaluate(:delimit, %{
          "value" => "1234.5",
          "separator" => ",",
          "precision_mode" => "fixed",
          "precision" => "2"
        })

      assert fixed.output == "1,234.50"
      assert fixed.code == "Humanizer.delimit(1234.5, separator: \",\", precision: 2)"
    end

    test "ordinal demonstrates English suffix exceptions" do
      for {value, expected} <- [{"1", "1st"}, {"11", "11th"}, {"23", "23rd"}, {"-1", "-1st"}] do
        assert Playground.evaluate(:ordinal, %{"value" => value}).output == expected
      end
    end

    test "invalid input preserves the last valid output and code" do
      valid =
        Playground.evaluate(:bytes, %{
          "value" => "1000",
          "system" => "decimal",
          "precision" => "1"
        })

      invalid = Playground.evaluate(:bytes, %{valid.params | "value" => "-1"}, valid)
      assert invalid.params["value"] == "-1"
      assert invalid.output == "1.0 KB"
      assert invalid.code == valid.code
      assert invalid.errors == %{"value" => "Enter a non-negative whole number."}
    end

    test "excessive precision is rejected without replacing the last valid result" do
      valid = Playground.evaluate(:number, %{"value" => "1234", "precision" => "2"})
      invalid = Playground.evaluate(:number, %{valid.params | "precision" => "999999999"}, valid)

      assert invalid.output == "1.23K"
      assert invalid.code == valid.code
      assert invalid.errors == %{"precision" => "Use a precision from 0 to 6."}
    end

    test "numeric validation is strict and field-specific" do
      assert Playground.evaluate(:number, %{"value" => "12px", "precision" => "1"}).errors ==
               %{"value" => "Enter a number."}

      assert Playground.evaluate(:percentage, %{"value" => "1", "precision" => "-1"}).errors ==
               %{"precision" => "Enter zero or a positive whole number."}

      assert Playground.evaluate(:delimit, %{
               "value" => "1000",
               "separator" => "",
               "precision_mode" => "natural",
               "precision" => "2"
             }).errors == %{"separator" => "Enter a separator."}

      assert Playground.evaluate(:ordinal, %{"value" => "2.5"}).errors ==
               %{"value" => "Enter a whole number."}
    end
  end

  describe "time, text, and list formatters" do
    @describetag :words

    test "duration exposes units and long or short formats" do
      assert Playground.evaluate(:duration, %{
               "value" => "3725",
               "units" => "2",
               "format" => "long"
             }).output == "1 hour, 2 minutes"

      assert Playground.evaluate(:duration, %{
               "value" => "3725",
               "units" => "all",
               "format" => "short"
             }).output == "1h 2m 5s"

      assert Playground.evaluate(:duration, %{
               "value" => "0.5",
               "units" => "2",
               "format" => "short"
             }).output == "<1s"
    end

    test "relative time uses explicit UTC value and reference" do
      params = %{
        "value" => "2026-05-13T10:00",
        "reference" => "2026-05-15T10:00",
        "format" => "long"
      }

      result = Playground.evaluate(:relative_time, params)
      assert result.output == "2 days ago"

      assert result.code ==
               "Humanizer.relative_time(~U[2026-05-13 10:00:00Z], ~U[2026-05-15 10:00:00Z], format: :long)"

      assert Playground.evaluate(:relative_time, %{params | "value" => "2026-05-15T13:00"}).output ==
               "in 3 hours"
    end

    test "truncate is Unicode-safe and supports word breaks" do
      assert Playground.evaluate(:truncate, %{
               "text" => "héllo wörld",
               "length" => "6",
               "omission" => "…",
               "break" => "char"
             }).output == "héllo…"

      assert Playground.evaluate(:truncate, %{
               "text" => "the quick brown fox",
               "length" => "9",
               "omission" => "…",
               "break" => "word"
             }).output == "the…"
    end

    test "list join exposes all documented options" do
      params = %{
        "items" => "Alice\nBob\nCharlie",
        "conjunction" => "and",
        "oxford" => "true",
        "max_enabled" => "false",
        "max" => "2",
        "other" => "other",
        "others" => "others"
      }

      assert Playground.evaluate(:list_join, params).output == "Alice, Bob, and Charlie"

      collapsed =
        Playground.evaluate(:list_join, %{
          params
          | "items" => "Alice\nBob\nCharlie\nDave\nEve",
            "max_enabled" => "true"
        })

      assert collapsed.output == "Alice, Bob, and 3 others"
      assert collapsed.code =~ "max: 2"
      assert collapsed.code =~ "other: \"other\""
      assert collapsed.code =~ "others: \"others\""
    end

    test "initial state, presets, and current time are deterministic" do
      state = Playground.initial_state()
      assert Enum.sort(Map.keys(state)) == Enum.sort(Playground.ids())

      assert Enum.all?(state, fn {_id, card} -> card.output && card.code && card.errors == %{} end)

      assert Playground.preset(:bytes, "zero").output == "0 B"

      relative = Map.fetch!(state, :relative_time)
      now = ~U[2026-08-10 14:37:42Z]
      updated = Playground.use_current_time(relative, now)
      assert updated.params["reference"] == "2026-08-10T14:37"
      assert updated.errors == %{}
    end

    test "invalid values stay field-specific and code strings stay escaped" do
      assert Playground.evaluate(:duration, %{
               "value" => "-1",
               "units" => "2",
               "format" => "long"
             }).errors == %{"value" => "Enter zero or a positive number."}

      assert Playground.evaluate(:relative_time, %{
               "value" => "not-a-date",
               "reference" => "2026-05-15T10:00",
               "format" => "long"
             }).errors == %{"value" => "Enter a valid UTC date and time."}

      assert Playground.evaluate(:truncate, %{
               "text" => "hello",
               "length" => "-1",
               "omission" => "…",
               "break" => "char"
             }).errors == %{"length" => "Enter zero or a positive whole number."}

      assert Playground.evaluate(:list_join, %{
               "items" => "Alice\nBob",
               "conjunction" => "and",
               "oxford" => "false",
               "max_enabled" => "true",
               "max" => "0",
               "other" => "other",
               "others" => "others"
             }).errors == %{"max" => "Enter a whole number greater than zero."}

      assert Playground.evaluate(:list_join, %{
               "items" => "Alice\nBob",
               "conjunction" => "and",
               "oxford" => "false",
               "max_enabled" => "true",
               "max" => "",
               "other" => "other",
               "others" => "others"
             }).errors == %{"max" => "Enter a whole number greater than zero."}

      escaped =
        Playground.evaluate(:truncate, %{
          "text" => "say \"hi\"\nnow",
          "length" => "40",
          "omission" => "…",
          "break" => "char"
        })

      assert escaped.code =~ ~s("say \\"hi\\"\\nnow")
    end
  end
end
