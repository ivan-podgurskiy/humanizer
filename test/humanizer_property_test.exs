defmodule HumanizerPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # Decimal mantissa is 0..999: a magnitude that rounds up to the base (e.g.
  # "1000.0 KB") is a bug and must advance to the next unit ("1.0 MB").
  @decimal_pattern ~r/^(0|[1-9]\d{0,2})(\.\d+)? (B|KB|MB|GB|TB|PB)$/
  # Binary units carry at 1024, not 1000, so the mantissa is 0..1023: e.g.
  # 1023 GiB is still under 1 TiB and must NOT carry. Only a rounded mantissa of
  # 1024 is a bug (it should advance to the next unit).
  @binary_pattern ~r/^(0|[1-9]\d{0,2}|10[01]\d|102[0-3])(\.\d+)? (B|KiB|MiB|GiB|TiB|PiB)$/

  property "bytes/2 always returns a valid size string (decimal)" do
    check all(n <- integer(0..(10 ** 15)), max_runs: 500) do
      result = Humanizer.bytes(n)
      assert result =~ @decimal_pattern
      refute result =~ ~r/[eE]/
    end
  end

  property "bytes/2 always returns a valid size string (binary)" do
    check all(n <- integer(0..(10 ** 15)), max_runs: 500) do
      result = Humanizer.bytes(n, system: :binary)
      assert result =~ @binary_pattern
      refute result =~ ~r/[eE]/
    end
  end

  # An optional leading "-", then digits grouped in threes by commas: the first
  # group is 1..3 digits, every following group is exactly 3.
  @delimit_pattern ~r/^-?\d{1,3}(,\d{3})*$/

  property "delimit/2 groups integers in threes without scientific notation" do
    check all(n <- integer(-(10 ** 15)..(10 ** 15)), max_runs: 500) do
      result = Humanizer.delimit(n)
      assert result =~ @delimit_pattern
      refute result =~ ~r/[eE]/
    end
  end
end
