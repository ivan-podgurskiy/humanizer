defmodule HumanizerPropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @decimal_pattern ~r/^\d+(\.\d+)? (B|KB|MB|GB|TB|PB)$/
  @binary_pattern ~r/^\d+(\.\d+)? (B|KiB|MiB|GiB|TiB|PiB)$/

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
