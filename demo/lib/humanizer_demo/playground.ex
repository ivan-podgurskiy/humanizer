defmodule HumanizerDemo.Playground do
  @moduledoc """
  Pure boundary between browser form values and Humanizer's public API.
  """

  alias HumanizerDemo.Playground.{Catalog, Evaluator}

  @type formatter_id ::
          :bytes
          | :number
          | :percentage
          | :delimit
          | :ordinal
          | :duration
          | :relative_time
          | :truncate
          | :list_join

  @type result :: %{
          id: formatter_id(),
          params: %{String.t() => String.t()},
          output: String.t() | nil,
          code: String.t() | nil,
          errors: %{optional(String.t()) => String.t()}
        }

  @spec ids() :: [formatter_id()]
  defdelegate ids(), to: Catalog

  @spec evaluate(formatter_id(), map(), result() | nil) :: result()
  def evaluate(id, params, previous \\ nil) do
    case Evaluator.evaluate(id, params) do
      {:ok, evaluated} ->
        %{id: id, params: params, output: evaluated.output, code: evaluated.code, errors: %{}}

      {:error, errors} ->
        %{
          id: id,
          params: params,
          output: previous && previous.output,
          code: previous && previous.code,
          errors: errors
        }
    end
  rescue
    error in ArgumentError ->
      %{
        id: id,
        params: params,
        output: previous && previous.output,
        code: previous && previous.code,
        errors: %{"base" => Exception.message(error)}
      }
  end

  @spec initial_state() :: %{required(formatter_id()) => result()}
  def initial_state do
    Map.new(ids(), fn id -> {id, evaluate(id, Catalog.default_params(id))} end)
  end

  @spec preset(formatter_id(), String.t(), result() | nil) :: result()
  def preset(id, preset_id, previous \\ nil) do
    previous = previous || evaluate(id, Catalog.default_params(id))
    params = Map.merge(previous.params, Catalog.preset!(id, preset_id).params)
    evaluate(id, params, previous)
  end

  @spec use_current_time(result(), DateTime.t()) :: result()
  def use_current_time(%{id: :relative_time} = previous, %DateTime{} = now) do
    reference = Calendar.strftime(now, "%Y-%m-%dT%H:%M")
    evaluate(:relative_time, Map.put(previous.params, "reference", reference), previous)
  end
end
