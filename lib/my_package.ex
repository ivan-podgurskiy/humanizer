defmodule MyPackage do
  @moduledoc """
  Public API surface for this library.

  Replace this module (and the app name in `mix.exs`) with your domain code.
  Keep the surface small—split into additional modules only when the package
  truly needs more than one concern.
  """

  @doc """
  Example pure function with doctest and property-test-friendly behavior.

  ## Examples

      iex> MyPackage.example(21)
      42

  """
  @spec example(integer()) :: integer()
  def example(n) when is_integer(n), do: n * 2
end
