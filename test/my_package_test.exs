defmodule MyPackageTest do
  use ExUnit.Case
  doctest MyPackage

  test "example/1 doubles integers" do
    assert MyPackage.example(3) == 6
  end
end
