defmodule HumanizerDemo.Playground.Parser do
  @moduledoc false

  @max_precision 6

  @spec parse_integer(map(), String.t(), keyword()) ::
          {:ok, integer()} | {:error, {String.t(), String.t()}}
  def parse_integer(params, key, opts \\ []) do
    message = Keyword.get(opts, :message, "Enter a whole number.")

    with value when is_binary(value) <- Map.get(params, key),
         {integer, ""} <- Integer.parse(value),
         true <- within_minimum?(integer, Keyword.get(opts, :min)) do
      {:ok, integer}
    else
      _ -> {:error, {key, message}}
    end
  end

  @spec parse_number(map(), String.t(), keyword()) ::
          {:ok, number()} | {:error, {String.t(), String.t()}}
  def parse_number(params, key, opts \\ []) do
    message = Keyword.get(opts, :message, "Enter a number.")

    with value when is_binary(value) <- Map.get(params, key),
         {:ok, number} <- strict_number(value),
         true <- within_minimum?(number, Keyword.get(opts, :min)) do
      {:ok, number}
    else
      _ -> {:error, {key, message}}
    end
  end

  @spec parse_precision(map(), String.t(), keyword()) ::
          {:ok, non_neg_integer()} | {:error, {String.t(), String.t()}}
  def parse_precision(params, key \\ "precision", opts \\ []) do
    message = Keyword.get(opts, :message, "Enter zero or a positive whole number.")

    case parse_integer(params, key, min: 0, message: message) do
      {:ok, precision} when precision <= @max_precision -> {:ok, precision}
      {:ok, _precision} -> {:error, {key, "Use a precision from 0 to #{@max_precision}."}}
      error -> error
    end
  end

  @spec parse_enum(map(), String.t(), map()) ::
          {:ok, term()} | {:error, {String.t(), String.t()}}
  def parse_enum(params, key, allowed) when is_map(allowed) do
    case Map.fetch(allowed, Map.get(params, key)) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, {key, "Choose a valid option."}}
    end
  end

  @spec parse_datetime(map(), String.t()) ::
          {:ok, DateTime.t()} | {:error, {String.t(), String.t()}}
  def parse_datetime(params, key) do
    with value when is_binary(value) <- Map.get(params, key),
         {:ok, naive} <- value |> normalize_datetime_local() |> NaiveDateTime.from_iso8601() do
      {:ok, DateTime.from_naive!(naive, "Etc/UTC")}
    else
      _ -> {:error, {key, "Enter a valid UTC date and time."}}
    end
  end

  @spec parse_optional_positive_integer(map(), String.t()) ::
          {:ok, pos_integer() | nil} | {:error, {String.t(), String.t()}}
  def parse_optional_positive_integer(params, key) do
    case Map.get(params, key) do
      "" ->
        {:ok, nil}

      _ ->
        parse_integer(params, key,
          min: 1,
          message: "Enter a whole number greater than zero."
        )
    end
  end

  @spec parse_lines(map(), String.t()) ::
          {:ok, [String.t()]} | {:error, {String.t(), String.t()}}
  def parse_lines(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) ->
        items = value |> String.split(~r/\r?\n/) |> Enum.reject(&(String.trim(&1) == ""))
        {:ok, items}

      _ ->
        {:error, {key, "Enter one item per line."}}
    end
  end

  defp strict_number(value) do
    case Integer.parse(value) do
      {integer, ""} ->
        {:ok, integer}

      _ ->
        case Float.parse(value) do
          {float, ""} -> {:ok, float}
          _ -> :error
        end
    end
  end

  defp normalize_datetime_local(<<date_and_time::binary-size(16)>>), do: date_and_time <> ":00"
  defp normalize_datetime_local(value), do: value

  defp within_minimum?(_value, nil), do: true
  defp within_minimum?(value, minimum), do: value >= minimum
end
