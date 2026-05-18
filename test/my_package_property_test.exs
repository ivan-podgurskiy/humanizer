defmodule MyPackagePropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  property "example/1 doubles its argument" do
    check all(n <- integer(-10_000..10_000), max_runs: 200) do
      assert MyPackage.example(n) == n + n
    end
  end
end
