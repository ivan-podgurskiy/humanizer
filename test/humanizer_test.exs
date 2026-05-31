defmodule HumanizerTest do
  use ExUnit.Case, async: true
  doctest Humanizer

  describe "bytes/2 edge cases" do
    test "zero is '0 B', not '0.0 B'" do
      assert Humanizer.bytes(0) == "0 B"
    end

    test "values below the unit boundary have no decimals" do
      assert Humanizer.bytes(999) == "999 B"
      assert Humanizer.bytes(512, system: :binary) == "512 B"
    end

    test "exact boundary at the first unit" do
      assert Humanizer.bytes(1000) == "1.0 KB"
      assert Humanizer.bytes(1024, system: :binary) == "1.0 KiB"
    end

    test "very large values use PB without scientific notation" do
      assert Humanizer.bytes(10 ** 15) == "1.0 PB"
    end

    test "precision: 0 has no trailing dot" do
      assert Humanizer.bytes(2_456_789, precision: 0) == "2 MB"
    end

    test "rounding carries up to the next unit instead of '1000.0 KB'" do
      assert Humanizer.bytes(999_950) == "1.0 MB"
      assert Humanizer.bytes(999_999_999) == "1.0 GB"
      assert Humanizer.bytes(999_950, precision: 0) == "1 MB"
    end

    test "binary system uses IEC suffixes" do
      assert Humanizer.bytes(2_456_789, system: :binary) == "2.3 MiB"
    end

    test "negative input raises ArgumentError" do
      assert_raise ArgumentError, fn -> Humanizer.bytes(-1) end
    end
  end

  describe "duration/2 edge cases" do
    test "zero renders as '0 seconds' (long) and '0s' (short)" do
      assert Humanizer.duration(0) == "0 seconds"
      assert Humanizer.duration(0, format: :short) == "0s"
    end

    test "fractional sub-second value is not silently '0 seconds'" do
      assert Humanizer.duration(0.5) == "less than a second"
      assert Humanizer.duration(0.5, format: :short) == "<1s"
    end

    test "caps at days for very large values (~3 years)" do
      assert Humanizer.duration(100_000_000, units: 1) == "1157 days"
    end

    test "negative input raises ArgumentError" do
      assert_raise ArgumentError, fn -> Humanizer.duration(-5) end
    end

    test "singular vs plural unit labels" do
      assert Humanizer.duration(3725, units: :all) == "1 hour, 2 minutes, 5 seconds"
      assert Humanizer.duration(7200, units: 1) == "2 hours"
    end
  end

  describe "relative_time/3 edge cases" do
    test "less than a minute reads as 'just now'" do
      now = ~U[2026-05-15 10:00:00Z]
      assert Humanizer.relative_time(~U[2026-05-15 09:59:30Z], now) == "just now"
    end

    test "future reads as 'in X', not '-X ago'" do
      now = ~U[2026-05-15 10:00:00Z]
      assert Humanizer.relative_time(~U[2026-05-15 13:00:00Z], now) == "in 3 hours"
    end

    test "exactly now reads as 'just now'" do
      now = ~U[2026-05-15 10:00:00Z]
      assert Humanizer.relative_time(now, now) == "just now"
    end

    test "different time zones are normalized to absolute instants" do
      utc = ~U[2026-05-15 10:00:00Z]
      # 12:00 in +02:00 is the same instant as 10:00 UTC
      {:ok, plus_two} = DateTime.from_naive(~N[2026-05-15 12:00:00], "Etc/UTC")

      plus_two = %{
        plus_two
        | utc_offset: 7200,
          std_offset: 0,
          zone_abbr: "+02",
          time_zone: "Etc/GMT-2"
      }

      assert Humanizer.relative_time(plus_two, utc) == "just now"
    end

    test "one-argument form uses now and reads as past" do
      past = DateTime.add(DateTime.utc_now(), -2 * 86_400, :second)
      assert Humanizer.relative_time(past) == "2 days ago"
    end
  end

  describe "number/2 edge cases" do
    test "zero is '0', not '0.0'" do
      assert Humanizer.number(0) == "0"
    end

    test "below 1000 has no suffix; 1000 is the boundary" do
      assert Humanizer.number(999) == "999"
      assert Humanizer.number(1000) == "1.0K"
    end

    test "negative numbers keep the sign" do
      assert Humanizer.number(-1_234) == "-1.2K"
    end

    test "float input is supported" do
      assert Humanizer.number(1234.5) == "1.2K"
    end

    test "trillions are the ceiling in v0.1" do
      assert Humanizer.number(10 ** 12) == "1.0T"
    end

    test "rounding carries up to the next suffix instead of '1000.0K'" do
      assert Humanizer.number(999_999) == "1.0M"
      assert Humanizer.number(999_999_999) == "1.0B"
    end
  end

  describe "ordinal/1 edge cases" do
    test "11, 12, 13 always take 'th'" do
      assert Humanizer.ordinal(11) == "11th"
      assert Humanizer.ordinal(12) == "12th"
      assert Humanizer.ordinal(13) == "13th"
    end

    test "21, 22, 23 take st/nd/rd" do
      assert Humanizer.ordinal(21) == "21st"
      assert Humanizer.ordinal(22) == "22nd"
      assert Humanizer.ordinal(23) == "23rd"
    end

    test "100 and 101" do
      assert Humanizer.ordinal(100) == "100th"
      assert Humanizer.ordinal(101) == "101st"
    end

    test "numbers ending in 11/12/13 take 'th'" do
      assert Humanizer.ordinal(111) == "111th"
      assert Humanizer.ordinal(112) == "112th"
      assert Humanizer.ordinal(113) == "113th"
    end

    test "zero is '0th'" do
      assert Humanizer.ordinal(0) == "0th"
    end

    test "negatives follow the same rule" do
      assert Humanizer.ordinal(-1) == "-1st"
    end
  end

  describe "list_join/2 edge cases" do
    test "empty list is an empty string" do
      assert Humanizer.list_join([]) == ""
    end

    test "single item is returned as-is" do
      assert Humanizer.list_join(["a"]) == "a"
    end

    test "two items never get a comma, even with oxford: true" do
      assert Humanizer.list_join(["a", "b"]) == "a and b"
      assert Humanizer.list_join(["a", "b"], oxford: true) == "a and b"
    end

    test "three items, with and without the oxford comma" do
      assert Humanizer.list_join(["a", "b", "c"]) == "a, b and c"
      assert Humanizer.list_join(["a", "b", "c"], oxford: true) == "a, b, and c"
    end

    test "custom conjunctions" do
      assert Humanizer.list_join(["a", "b", "c"], conjunction: "or") == "a, b or c"
      assert Humanizer.list_join(["a", "b", "c"], conjunction: "&") == "a, b & c"
    end
  end
end
