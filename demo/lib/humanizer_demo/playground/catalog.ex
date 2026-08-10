defmodule HumanizerDemo.Playground.Catalog do
  @moduledoc false

  @ids [
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

  @defaults %{
    bytes: %{"value" => "2456789", "system" => "decimal", "precision" => "1"},
    number: %{"value" => "1234567", "precision" => "1"},
    percentage: %{"value" => "0.1234", "precision" => "1"},
    delimit: %{
      "value" => "1234567",
      "separator" => ",",
      "precision_mode" => "natural",
      "precision" => "2"
    },
    ordinal: %{"value" => "23"},
    duration: %{"value" => "3725", "units" => "2", "format" => "long"},
    relative_time: %{
      "value" => "2026-05-13T10:00",
      "reference" => "2026-05-15T10:00",
      "format" => "long"
    },
    truncate: %{
      "text" => "the quick brown fox",
      "length" => "9",
      "omission" => "…",
      "break" => "char"
    },
    list_join: %{
      "items" => "Alice\nBob\nCharlie",
      "conjunction" => "and",
      "oxford" => "false",
      "max_enabled" => "false",
      "max" => "2",
      "other" => "other",
      "others" => "others"
    }
  }

  @presets %{
    bytes: [
      %{id: "zero", label: "Zero", params: %{"value" => "0"}},
      %{id: "boundary", label: "999 B", params: %{"value" => "999"}},
      %{id: "carry", label: "Carry", params: %{"value" => "999950"}},
      %{id: "binary", label: "Binary", params: %{"value" => "2456789", "system" => "binary"}},
      %{id: "petabyte", label: "Petabyte", params: %{"value" => "1000000000000000"}}
    ],
    number: [
      %{id: "zero", label: "Zero", params: %{"value" => "0"}},
      %{id: "below-boundary", label: "999", params: %{"value" => "999"}},
      %{id: "boundary", label: "1K boundary", params: %{"value" => "1000"}},
      %{id: "negative", label: "Negative", params: %{"value" => "-1234"}},
      %{id: "carry", label: "Carry", params: %{"value" => "999999"}},
      %{id: "trillion", label: "Trillion", params: %{"value" => "1000000000000"}}
    ],
    percentage: [
      %{id: "zero", label: "Zero", params: %{"value" => "0"}},
      %{id: "ratio", label: "Fraction", params: %{"value" => "0.1234"}},
      %{id: "whole", label: "One is 100%", params: %{"value" => "1"}},
      %{id: "negative", label: "Negative", params: %{"value" => "-0.125", "precision" => "0"}},
      %{id: "over", label: "Over 100%", params: %{"value" => "1.25"}}
    ],
    delimit: [
      %{id: "integer", label: "Integer", params: %{"value" => "1234567"}},
      %{id: "negative", label: "Negative", params: %{"value" => "-1234567"}},
      %{id: "float", label: "Natural float", params: %{"value" => "1234.5"}},
      %{
        id: "fixed",
        label: "Fixed decimals",
        params: %{"value" => "1234.5", "precision_mode" => "fixed", "precision" => "2"}
      },
      %{id: "space", label: "Space separator", params: %{"separator" => " "}}
    ],
    ordinal: [
      %{id: "zero", label: "Zero", params: %{"value" => "0"}},
      %{id: "first", label: "First", params: %{"value" => "1"}},
      %{id: "second", label: "Second", params: %{"value" => "2"}},
      %{id: "third", label: "Third", params: %{"value" => "3"}},
      %{id: "eleventh", label: "Eleventh", params: %{"value" => "11"}},
      %{id: "twelfth", label: "Twelfth", params: %{"value" => "12"}},
      %{id: "thirteenth", label: "Thirteenth", params: %{"value" => "13"}},
      %{id: "twenty-first", label: "Twenty-first", params: %{"value" => "21"}},
      %{id: "twenty-second", label: "Twenty-second", params: %{"value" => "22"}},
      %{id: "twenty-third", label: "Twenty-third", params: %{"value" => "23"}},
      %{id: "negative", label: "Negative", params: %{"value" => "-1"}}
    ],
    duration: [
      %{id: "zero", label: "Zero", params: %{"value" => "0"}},
      %{id: "subsecond", label: "Sub-second", params: %{"value" => "0.5"}},
      %{id: "seconds", label: "45 seconds", params: %{"value" => "45"}},
      %{id: "all", label: "All units", params: %{"value" => "3725", "units" => "all"}},
      %{id: "large", label: "Large", params: %{"value" => "100000000", "units" => "1"}}
    ],
    relative_time: [
      %{id: "now", label: "Just now", params: %{"value" => "2026-05-15T10:00"}},
      %{id: "past", label: "Past", params: %{"value" => "2026-05-13T10:00"}},
      %{id: "future", label: "Future", params: %{"value" => "2026-05-15T13:00"}},
      %{id: "week", label: "Week", params: %{"value" => "2026-05-08T10:00"}},
      %{id: "month", label: "Month", params: %{"value" => "2026-04-01T10:00"}},
      %{id: "year", label: "Year", params: %{"value" => "2025-05-15T10:00"}}
    ],
    truncate: [
      %{id: "unchanged", label: "Unchanged", params: %{"text" => "hi there", "length" => "20"}},
      %{id: "character", label: "Character", params: %{"length" => "9", "break" => "char"}},
      %{id: "word", label: "Word", params: %{"length" => "9", "break" => "word"}},
      %{id: "custom", label: "Custom omission", params: %{"length" => "12", "omission" => "..."}},
      %{
        id: "omission-limit",
        label: "Omission limit",
        params: %{"text" => "abcdef", "length" => "1", "omission" => "…"}
      },
      %{id: "unicode", label: "Unicode", params: %{"text" => "héllo wörld", "length" => "6"}}
    ],
    list_join: [
      %{id: "empty", label: "Empty", params: %{"items" => ""}},
      %{id: "one", label: "One item", params: %{"items" => "Alice"}},
      %{id: "two", label: "Two items", params: %{"items" => "Alice\nBob"}},
      %{id: "oxford", label: "Oxford comma", params: %{"oxford" => "true"}},
      %{id: "or", label: "Alternative", params: %{"conjunction" => "or"}},
      %{
        id: "collapsed",
        label: "Collapsed",
        params: %{
          "items" => "Alice\nBob\nCharlie\nDave\nEve",
          "max_enabled" => "true",
          "max" => "2"
        }
      }
    ]
  }

  @spec ids() :: [atom()]
  def ids, do: @ids

  @spec default_params(atom()) :: %{String.t() => String.t()}
  def default_params(id), do: Map.fetch!(@defaults, id)

  @spec presets(atom()) :: [map()]
  def presets(id), do: Map.fetch!(@presets, id)

  @spec preset!(atom(), String.t()) :: map()
  def preset!(id, preset_id) do
    id |> presets() |> Enum.find(&(&1.id == preset_id)) ||
      raise KeyError, key: preset_id, term: id
  end
end
