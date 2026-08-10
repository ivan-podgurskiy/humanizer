defmodule HumanizerDemo.Playground.Evaluator do
  @moduledoc false

  alias HumanizerDemo.Playground.{Code, Parser}

  @spec evaluate(atom(), map()) ::
          {:ok, %{output: String.t(), code: String.t()}} | {:error, %{String.t() => String.t()}}
  def evaluate(:bytes, params) do
    with {:ok, value} <-
           Parser.parse_integer(params, "value",
             min: 0,
             message: "Enter a non-negative whole number."
           ),
         {:ok, system} <-
           Parser.parse_enum(params, "system", %{"decimal" => :decimal, "binary" => :binary}),
         {:ok, precision} <- Parser.parse_precision(params) do
      opts = [system: system, precision: precision]
      success(Humanizer.bytes(value, opts), Code.call("bytes", [value], opts))
    else
      error -> failure(error)
    end
  end

  def evaluate(:number, params) do
    with {:ok, value} <- Parser.parse_number(params, "value"),
         {:ok, precision} <- Parser.parse_precision(params) do
      opts = [precision: precision]
      success(Humanizer.number(value, opts), Code.call("number", [value], opts))
    else
      error -> failure(error)
    end
  end

  def evaluate(:percentage, params) do
    with {:ok, value} <- Parser.parse_number(params, "value"),
         {:ok, precision} <- Parser.parse_precision(params) do
      opts = [precision: precision]
      success(Humanizer.percentage(value, opts), Code.call("percentage", [value], opts))
    else
      error -> failure(error)
    end
  end

  def evaluate(:delimit, params) do
    with {:ok, value} <- Parser.parse_number(params, "value"),
         {:ok, separator} <- parse_separator(params),
         {:ok, precision_mode} <-
           Parser.parse_enum(params, "precision_mode", %{
             "natural" => :natural,
             "fixed" => :fixed
           }),
         {:ok, opts} <- delimit_options(params, separator, precision_mode) do
      success(Humanizer.delimit(value, opts), Code.call("delimit", [value], opts))
    else
      error -> failure(error)
    end
  end

  def evaluate(:ordinal, params) do
    case Parser.parse_integer(params, "value") do
      {:ok, value} -> success(Humanizer.ordinal(value), Code.call("ordinal", [value]))
      error -> failure(error)
    end
  end

  def evaluate(:duration, params) do
    with {:ok, value} <-
           Parser.parse_number(params, "value",
             min: 0,
             message: "Enter zero or a positive number."
           ),
         {:ok, units} <-
           Parser.parse_enum(params, "units", %{
             "1" => 1,
             "2" => 2,
             "3" => 3,
             "4" => 4,
             "all" => :all
           }),
         {:ok, format} <- format(params) do
      opts = [units: units, format: format]
      success(Humanizer.duration(value, opts), Code.call("duration", [value], opts))
    else
      error -> failure(error)
    end
  end

  def evaluate(:relative_time, params) do
    with {:ok, value} <- Parser.parse_datetime(params, "value"),
         {:ok, reference} <- Parser.parse_datetime(params, "reference"),
         {:ok, format} <- format(params) do
      opts = [format: format]

      success(
        Humanizer.relative_time(value, reference, opts),
        Code.call("relative_time", [value, reference], opts)
      )
    else
      error -> failure(error)
    end
  end

  def evaluate(:truncate, params) do
    with {:ok, text} <- required_binary(params, "text", "Enter text to truncate."),
         {:ok, length} <-
           Parser.parse_integer(params, "length",
             min: 0,
             message: "Enter zero or a positive whole number."
           ),
         {:ok, omission} <- binary_value(params, "omission"),
         {:ok, break_mode} <-
           Parser.parse_enum(params, "break", %{"char" => :char, "word" => :word}) do
      opts = [omission: omission, break: break_mode]
      success(Humanizer.truncate(text, length, opts), Code.call("truncate", [text, length], opts))
    else
      error -> failure(error)
    end
  end

  def evaluate(:list_join, params) do
    with {:ok, items} <- Parser.parse_lines(params, "items"),
         {:ok, conjunction} <- binary_value(params, "conjunction"),
         {:ok, oxford} <-
           Parser.parse_enum(params, "oxford", %{"false" => false, "true" => true}),
         {:ok, max_enabled} <-
           Parser.parse_enum(params, "max_enabled", %{"false" => false, "true" => true}),
         {:ok, opts} <- list_options(params, conjunction, oxford, max_enabled) do
      success(Humanizer.list_join(items, opts), Code.call("list_join", [items], opts))
    else
      error -> failure(error)
    end
  end

  defp parse_separator(%{"separator" => separator}) when separator != "", do: {:ok, separator}
  defp parse_separator(_params), do: {:error, {"separator", "Enter a separator."}}

  defp delimit_options(_params, separator, :natural), do: {:ok, [separator: separator]}

  defp delimit_options(params, separator, :fixed) do
    case Parser.parse_precision(params) do
      {:ok, precision} -> {:ok, [separator: separator, precision: precision]}
      error -> error
    end
  end

  defp list_options(_params, conjunction, oxford, false) do
    {:ok, [conjunction: conjunction, oxford: oxford]}
  end

  defp list_options(params, conjunction, oxford, true) do
    with {:ok, max} when is_integer(max) <- Parser.parse_optional_positive_integer(params, "max"),
         {:ok, other} <- binary_value(params, "other"),
         {:ok, others} <- binary_value(params, "others") do
      {:ok,
       [
         conjunction: conjunction,
         oxford: oxford,
         max: max,
         other: other,
         others: others
       ]}
    else
      {:ok, nil} -> {:error, {"max", "Enter a whole number greater than zero."}}
      error -> error
    end
  end

  defp format(params) do
    Parser.parse_enum(params, "format", %{"long" => :long, "short" => :short})
  end

  defp required_binary(params, key, message) do
    case Map.get(params, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, {key, message}}
    end
  end

  defp binary_value(params, key) do
    case Map.get(params, key) do
      value when is_binary(value) -> {:ok, value}
      _ -> {:error, {key, "Enter a value."}}
    end
  end

  defp success(output, code), do: {:ok, %{output: output, code: code}}
  defp failure({:error, {key, message}}), do: {:error, %{key => message}}
end
