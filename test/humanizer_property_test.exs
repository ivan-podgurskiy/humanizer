defmodule HumanizerPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # Mantissa is 0..999: a magnitude that rounds up to the base (e.g. "1000.0 KB")
  # is a bug and must advance to the next unit ("1.0 MB").
  @decimal_pattern ~r/^(0|[1-9]\d{0,2})(\.\d+)? (B|KB|MB|GB|TB|PB)$/
  @binary_pattern ~r/^(0|[1-9]\d{0,2})(\.\d+)? (B|KiB|MiB|GiB|TiB|PiB)$/

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
end
