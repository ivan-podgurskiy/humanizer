defmodule Humanizer do
  @moduledoc """
  Human-friendly formatting helpers for Elixir.

  A small, flat set of pure functions that turn raw values into the kind of
  strings you show to people:

    * `bytes/2` — `2_456_789` → `"2.5 MB"`
    * `duration/2` — `3725` → `"1 hour, 2 minutes"`
    * `relative_time/3` — a `DateTime` → `"2 days ago"`
    * `number/2` — `1_234_567` → `"1.2M"`
    * `delimit/2` — `1_234_567` → `"1,234,567"`
    * `ordinal/1` — `23` → `"23rd"`
    * `truncate/3` — `"the quick brown fox", 9` → `"the quic…"`
    * `list_join/2` — `["Alice", "Bob", "Charlie"]` → `"Alice, Bob and Charlie"`

  ## Design

    * **English only.** No localization in v0.1. For real i18n use `ex_cldr`.
    * **No global config.** Every option is a keyword passed to the function.
    * **One rounding rule.** Decimal output uses round-half-away-from-zero with a
      single fractional digit by default (`:precision` to override).
    * **No scientific notation, ever.** Numbers are formatted from integers, so
      values up to `10 ** 15` never come out as `"1.0e15"`.
  """

  @byte_suffixes_decimal ~w(B KB MB GB TB PB)
  @byte_suffixes_binary ~w(B KiB MiB GiB TiB PiB)
  @number_suffixes ["", "K", "M", "B", "T"]

  @duration_units [
    {86_400, "day", "days", "d"},
    {3_600, "hour", "hours", "h"},
    {60, "minute", "minutes", "m"},
    {1, "second", "seconds", "s"}
  ]

  # Coarse, fixed-width units for relative-time display only. Months and years
  # are linear approximations (30 and 365 days) — deliberately distinct from the
  # calendar math that `duration/2` omits.
  @relative_units [
    {31_536_000, "year", "years", "y"},
    {2_592_000, "month", "months", "mo"},
    {604_800, "week", "weeks", "w"},
    {86_400, "day", "days", "d"},
    {3_600, "hour", "hours", "h"},
    {60, "minute", "minutes", "m"}
  ]

  @doc """
  Formats a byte count as a human-readable size.

  Uses decimal (SI, base 1000) units by default. Pass `system: :binary` for
  IEC (base 1024) units. Precision defaults to one fractional digit.

  ## Options

    * `:system` — `:decimal` (default) or `:binary`
    * `:precision` — number of fractional digits (default `1`)

  ## Examples

      iex> Humanizer.bytes(2_456_789)
      "2.5 MB"

      iex> Humanizer.bytes(2_456_789, system: :binary)
      "2.3 MiB"

      iex> Humanizer.bytes(2_456_789, precision: 2)
      "2.46 MB"

      iex> Humanizer.bytes(0)
      "0 B"

  """
  @spec bytes(non_neg_integer(), keyword()) :: String.t()
  def bytes(n, opts \\ [])

  def bytes(n, opts) when is_integer(n) and n >= 0 do
    {base, suffixes} =
      case Keyword.get(opts, :system, :decimal) do
        :decimal ->
          {1000, @byte_suffixes_decimal}

        :binary ->
          {1024, @byte_suffixes_binary}

        other ->
          raise ArgumentError, "unknown :system #{inspect(other)}, expected :decimal or :binary"
      end

    precision = Keyword.get(opts, :precision, 1)
    max_index = length(suffixes) - 1

    cond do
      n == 0 ->
        "0 B"

      n < base ->
        "#{n} B"

      true ->
        {value, index} =
          scale_with_carry(n, base, scale_index(n, base, max_index), max_index, precision)

        "#{format_scaled(value, precision)} #{Enum.at(suffixes, index)}"
    end
  end

  def bytes(n, _opts) when is_integer(n) do
    raise ArgumentError, "bytes/2 expects a non-negative integer, got: #{inspect(n)}"
  end

  @doc """
  Formats a number with a magnitude suffix (`K`, `M`, `B`, `T`).

  Accepts integers and floats, positive or negative. Values below 1000 are
  rendered without a suffix or decimals. The ceiling in v0.1 is trillions (`T`).

  ## Options

    * `:precision` — number of fractional digits for suffixed values (default `1`)

  ## Examples

      iex> Humanizer.number(1_234)
      "1.2K"

      iex> Humanizer.number(1_234_567)
      "1.2M"

      iex> Humanizer.number(999)
      "999"

      iex> Humanizer.number(-1_234, precision: 2)
      "-1.23K"

  """
  @spec number(number(), keyword()) :: String.t()
  def number(n, opts \\ []) when is_number(n) do
    precision = Keyword.get(opts, :precision, 1)
    sign = if n < 0, do: "-", else: ""
    abs_n = abs(n)
    max_index = length(@number_suffixes) - 1

    {value, index} =
      scale_with_carry(abs_n, 1000, scale_index(abs_n, 1000, max_index), max_index, precision)

    if index == 0 do
      sign <> Integer.to_string(round_half_away(abs_n))
    else
      sign <> format_scaled(value, precision) <> Enum.at(@number_suffixes, index)
    end
  end

  @doc """
  Inserts a thousands separator into a number.

  Groups the integer part in threes. Integers render with no fractional part;
  floats keep their own decimals. Pass `:precision` to force a fixed number of
  fractional digits (handy for currency). Output is never in scientific notation.

  ## Options

    * `:separator` — the grouping separator (default `","`)
    * `:precision` — fixed number of fractional digits (default: keep the value's
      natural decimals; integers show none)

  ## Examples

      iex> Humanizer.delimit(1_234_567)
      "1,234,567"

      iex> Humanizer.delimit(1_234_567, separator: " ")
      "1 234 567"

      iex> Humanizer.delimit(1234.5, precision: 2)
      "1,234.50"

      iex> Humanizer.delimit(-1000)
      "-1,000"

  """
  @spec delimit(number(), keyword()) :: String.t()
  def delimit(n, opts \\ []) when is_number(n) do
    separator = Keyword.get(opts, :separator, ",")
    precision = Keyword.get(opts, :precision)
    sign = if n < 0, do: "-", else: ""
    {int_str, frac_str} = delimit_parts(abs(n), precision)
    sign <> group_digits(int_str, separator) <> frac_str
  end

  @doc """
  Returns the integer with its English ordinal suffix.

  Correctly handles the 11/12/13 exceptions and negative numbers.

  ## Examples

      iex> Humanizer.ordinal(1)
      "1st"

      iex> Humanizer.ordinal(11)
      "11th"

      iex> Humanizer.ordinal(23)
      "23rd"

      iex> Humanizer.ordinal(-1)
      "-1st"

  """
  @spec ordinal(integer()) :: String.t()
  def ordinal(n) when is_integer(n) do
    Integer.to_string(n) <> ordinal_suffix(abs(n))
  end

  @doc """
  Truncates a string to at most `length` characters, appending an omission marker.

  Counts graphemes, so it is Unicode-safe. If the text already fits within
  `length`, it is returned unchanged. With `break: :word` the cut is moved back
  to the previous whitespace boundary so words are not split mid-way. The
  omission marker counts toward `length`.

  ## Options

    * `:omission` — marker appended when text is cut (default `"…"`)
    * `:break` — `:char` (default) cuts anywhere, `:word` cuts on whitespace

  ## Examples

      iex> Humanizer.truncate("the quick brown fox", 9)
      "the quic…"

      iex> Humanizer.truncate("the quick brown fox", 9, break: :word)
      "the…"

      iex> Humanizer.truncate("hi there", 20)
      "hi there"

      iex> Humanizer.truncate("the quick brown fox", 12, omission: "...")
      "the quick..."

  """
  @spec truncate(String.t(), non_neg_integer(), keyword()) :: String.t()
  def truncate(text, length, opts \\ [])

  def truncate(text, length, opts)
      when is_binary(text) and is_integer(length) and length >= 0 do
    if String.length(text) <= length do
      text
    else
      omission = Keyword.get(opts, :omission, "…")
      break = Keyword.get(opts, :break, :char)
      keep = max(length - String.length(omission), 0)

      text
      |> String.slice(0, keep)
      |> apply_break(break)
      |> Kernel.<>(omission)
    end
  end

  @doc """
  Joins a list of strings into a human-readable enumeration.

  ## Options

    * `:conjunction` — word before the last item (default `"and"`)
    * `:oxford` — add a serial comma before the conjunction (default `false`).
      Has no effect on two-item lists.
    * `:max` — show at most this many items, collapsing the rest into a count
      (`"Alice, Bob and 3 others"`). Only applies when the list is longer.
    * `:other` / `:others` — singular/plural noun for the collapsed remainder
      (defaults `"other"` / `"others"`)

  ## Examples

      iex> Humanizer.list_join(["Alice", "Bob", "Charlie"])
      "Alice, Bob and Charlie"

      iex> Humanizer.list_join(["Alice", "Bob"])
      "Alice and Bob"

      iex> Humanizer.list_join(["Alice", "Bob", "Charlie"], oxford: true)
      "Alice, Bob, and Charlie"

      iex> Humanizer.list_join(["Alice", "Bob", "Charlie"], conjunction: "or")
      "Alice, Bob or Charlie"

      iex> Humanizer.list_join(["Alice", "Bob", "Charlie", "Dave", "Eve"], max: 2)
      "Alice, Bob and 3 others"

  """
  @spec list_join([String.t()], keyword()) :: String.t()
  def list_join(items, opts \\ [])

  def list_join(items, opts) when is_list(items) do
    case Keyword.get(opts, :max) do
      max when is_integer(max) and max > 0 and length(items) > max ->
        {shown, rest} = Enum.split(items, max)
        count = length(rest)

        noun =
          if count == 1,
            do: Keyword.get(opts, :other, "other"),
            else: Keyword.get(opts, :others, "others")

        do_list_join(shown ++ ["#{count} #{noun}"], opts)

      _ ->
        do_list_join(items, opts)
    end
  end

  @doc """
  Formats a duration given in seconds as words.

  Breaks the duration down into days, hours, minutes and seconds (months and
  years are out of scope in v0.1). By default the two most significant non-zero
  units are shown.

  ## Options

    * `:units` — number of units to show, or `:all` (default `2`)
    * `:format` — `:long` (default, `"1 hour"`) or `:short` (`"1h"`)

  Raises `ArgumentError` for negative input.

  ## Examples

      iex> Humanizer.duration(3725)
      "1 hour, 2 minutes"

      iex> Humanizer.duration(3725, units: 1)
      "1 hour"

      iex> Humanizer.duration(3725, units: :all)
      "1 hour, 2 minutes, 5 seconds"

      iex> Humanizer.duration(45, format: :short)
      "45s"

  """
  @spec duration(number(), keyword()) :: String.t()
  def duration(seconds, opts \\ [])

  def duration(seconds, _opts) when is_number(seconds) and seconds < 0 do
    raise ArgumentError,
          "duration/2 expects a non-negative number of seconds, got: #{inspect(seconds)}"
  end

  def duration(seconds, opts) when is_number(seconds) do
    format = Keyword.get(opts, :format, :long)
    total = trunc(seconds)

    cond do
      total == 0 and seconds == 0 ->
        zero_duration(format)

      total == 0 ->
        sub_second_duration(format)

      true ->
        units = Keyword.get(opts, :units, 2)

        @duration_units
        |> breakdown(total)
        |> Enum.filter(fn {count, _} -> count > 0 end)
        |> take_units(units)
        |> Enum.map_join(duration_separator(format), &render_unit(&1, format))
    end
  end

  @doc """
  Formats a `DateTime` relative to now (or to a given reference time).

  Past times read as `"X ago"`, future times as `"in X"`, and anything within a
  minute as `"just now"`. Both arguments are compared as absolute instants, so
  time zones are handled correctly. Units range from minutes up to years; weeks,
  months and years are coarse fixed-width approximations (7 / 30 / 365 days) for
  display only — for exact calendar math use `Date`/`DateTime` directly.

  ## Options

    * `:format` — `:long` (default, `"2 days ago"`) or `:short` (`"2d ago"`,
      `"in 3h"`, `"now"`). Short uses `m` for minutes and `mo` for months.

  ## Examples

      iex> Humanizer.relative_time(~U[2026-05-13 10:00:00Z], ~U[2026-05-15 10:00:00Z])
      "2 days ago"

      iex> Humanizer.relative_time(~U[2026-05-15 13:00:00Z], ~U[2026-05-15 10:00:00Z])
      "in 3 hours"

      iex> Humanizer.relative_time(~U[2026-05-15 10:00:00Z], ~U[2026-05-15 10:00:00Z])
      "just now"

      iex> Humanizer.relative_time(~U[2026-04-01 10:00:00Z], ~U[2026-05-15 10:00:00Z])
      "1 month ago"

      iex> Humanizer.relative_time(~U[2026-05-13 10:00:00Z], ~U[2026-05-15 10:00:00Z], format: :short)
      "2d ago"

  """
  @spec relative_time(DateTime.t(), keyword()) :: String.t()
  @spec relative_time(DateTime.t(), DateTime.t(), keyword()) :: String.t()
  def relative_time(datetime, now_or_opts \\ [])

  def relative_time(%DateTime{} = datetime, %DateTime{} = now) do
    relative_time(datetime, now, [])
  end

  def relative_time(%DateTime{} = datetime, opts) when is_list(opts) do
    relative_time(datetime, DateTime.utc_now(), opts)
  end

  def relative_time(%DateTime{} = datetime, %DateTime{} = now, opts) when is_list(opts) do
    format = Keyword.get(opts, :format, :long)
    diff = DateTime.diff(now, datetime, :second)
    abs_diff = abs(diff)

    cond do
      abs_diff < 60 -> just_now(format)
      diff >= 0 -> "#{relative_phrase(abs_diff, format)} ago"
      true -> "in #{relative_phrase(abs_diff, format)}"
    end
  end

  # --- internal helpers ---

  defp ordinal_suffix(abs_n) do
    cond do
      rem(abs_n, 100) in 11..13 -> "th"
      rem(abs_n, 10) == 1 -> "st"
      rem(abs_n, 10) == 2 -> "nd"
      rem(abs_n, 10) == 3 -> "rd"
      true -> "th"
    end
  end

  defp do_list_join([], _opts), do: ""
  defp do_list_join([single], _opts), do: single

  defp do_list_join([first, second], opts) do
    "#{first} #{conjunction(opts)} #{second}"
  end

  defp do_list_join(items, opts) do
    {init, [last]} = Enum.split(items, -1)
    oxford = if Keyword.get(opts, :oxford, false), do: ",", else: ""
    "#{Enum.join(init, ", ")}#{oxford} #{conjunction(opts)} #{last}"
  end

  defp conjunction(opts), do: Keyword.get(opts, :conjunction, "and")

  # --- delimit helpers ---

  defp delimit_parts(abs_n, nil) when is_integer(abs_n), do: {Integer.to_string(abs_n), ""}

  defp delimit_parts(abs_n, nil) when is_float(abs_n) do
    case String.split(:erlang.float_to_binary(abs_n, [:short]), ".") do
      [int_part, frac_part] -> {int_part, "." <> frac_part}
      [int_part] -> {int_part, ""}
    end
  end

  defp delimit_parts(abs_n, 0), do: {Integer.to_string(round_half_away(abs_n)), ""}

  defp delimit_parts(abs_n, precision) when is_integer(precision) and precision > 0 do
    scale = pow_int(10, precision)
    scaled = round_half_away(abs_n * scale)
    integer_part = div(scaled, scale)
    fractional = scaled |> rem(scale) |> Integer.to_string() |> String.pad_leading(precision, "0")
    {Integer.to_string(integer_part), "." <> fractional}
  end

  defp group_digits(int_str, separator) do
    int_str
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&(&1 |> Enum.reverse() |> Enum.join()))
    |> Enum.reverse()
    |> Enum.join(separator)
  end

  # --- truncate helpers ---

  defp apply_break(head, :word) do
    case Regex.run(~r/^(.*\S)\s+\S*$/u, head) do
      [_, prefix] -> prefix
      _ -> String.trim_trailing(head)
    end
  end

  defp apply_break(head, _char), do: head

  defp zero_duration(:short), do: "0s"
  defp zero_duration(_), do: "0 seconds"

  defp sub_second_duration(:short), do: "<1s"
  defp sub_second_duration(_), do: "less than a second"

  defp breakdown(units, total) do
    {parts, _remaining} =
      Enum.reduce(units, {[], total}, fn {secs, singular, plural, short}, {acc, remaining} ->
        count = div(remaining, secs)
        {[{count, {singular, plural, short}} | acc], remaining - count * secs}
      end)

    Enum.reverse(parts)
  end

  defp take_units(parts, :all), do: parts
  defp take_units(parts, count) when is_integer(count) and count > 0, do: Enum.take(parts, count)

  defp duration_separator(:short), do: " "
  defp duration_separator(_), do: ", "

  defp render_unit({count, {_singular, _plural, short}}, :short), do: "#{count}#{short}"

  defp render_unit({count, {singular, _plural, _short}}, _) when count == 1,
    do: "#{count} #{singular}"

  defp render_unit({count, {_singular, plural, _short}}, _), do: "#{count} #{plural}"

  defp just_now(:short), do: "now"
  defp just_now(_), do: "just now"

  defp relative_phrase(abs_diff, format) do
    {secs, singular, plural, short} =
      Enum.find(@relative_units, fn {secs, _, _, _} -> abs_diff >= secs end)

    value = div(abs_diff, secs)

    case format do
      :short -> "#{value}#{short}"
      _ -> "#{value} #{if value == 1, do: singular, else: plural}"
    end
  end

  # Largest index `i` (0..max) such that `value >= base ** i`.
  defp scale_index(value, base, max) do
    Enum.reduce_while(1..max, 0, fn i, _acc ->
      if value >= pow_int(base, i), do: {:cont, i}, else: {:halt, i - 1}
    end)
  end

  # Returns `{value, index}` for the chosen magnitude, advancing to the next unit
  # when rounding at the requested precision would carry the mantissa up to `base`
  # (e.g. 999_950 bytes rounds to "1.0 MB", not "1000.0 KB").
  defp scale_with_carry(n, base, index, max_index, precision) do
    value = n / pow_int(base, index)

    if index < max_index and rounds_to_base?(value, base, precision) do
      scale_with_carry(n, base, index + 1, max_index, precision)
    else
      {value, index}
    end
  end

  defp rounds_to_base?(value, base, precision) do
    scale = pow_int(10, precision)
    round_half_away(value * scale) >= base * scale
  end

  defp pow_int(_base, 0), do: 1
  defp pow_int(base, exp) when exp > 0, do: base * pow_int(base, exp - 1)

  # Rounds a float to the nearest integer, half away from zero.
  defp round_half_away(value) when value >= 0, do: trunc(value + 0.5)
  defp round_half_away(value), do: -trunc(-value + 0.5)

  # Formats a float with exactly `precision` fractional digits, built from
  # integers so the result is never in scientific notation.
  defp format_scaled(value, 0), do: Integer.to_string(round_half_away(value))

  defp format_scaled(value, precision) when is_integer(precision) and precision > 0 do
    scale = pow_int(10, precision)
    scaled = round_half_away(value * scale)
    sign = if scaled < 0, do: "-", else: ""
    abs_scaled = abs(scaled)
    integer_part = div(abs_scaled, scale)

    fractional =
      abs_scaled |> rem(scale) |> Integer.to_string() |> String.pad_leading(precision, "0")

    "#{sign}#{integer_part}.#{fractional}"
  end
end
