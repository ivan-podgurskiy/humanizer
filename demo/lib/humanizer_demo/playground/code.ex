defmodule HumanizerDemo.Playground.Code do
  @moduledoc false

  @spec call(String.t(), [term()], keyword()) :: String.t()
  def call(function, args, opts \\ []) do
    rendered_args = Enum.map_join(args, ", ", &inspect/1)

    rendered_opts =
      Enum.map_join(opts, ", ", fn {key, value} ->
        "#{key}: #{inspect(value)}"
      end)

    separator = if rendered_args != "" and rendered_opts != "", do: ", ", else: ""

    "Humanizer.#{function}(#{rendered_args}#{separator}#{rendered_opts})"
  end
end
