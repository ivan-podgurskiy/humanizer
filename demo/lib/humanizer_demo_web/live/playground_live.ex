defmodule HumanizerDemoWeb.PlaygroundLive do
  @moduledoc false

  use HumanizerDemoWeb, :live_view

  alias HumanizerDemo.Playground
  alias HumanizerDemo.Playground.Catalog

  @ids_by_string Map.new(Playground.ids(), &{Atom.to_string(&1), &1})

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Humanizer — human-friendly formatting for Elixir",
       cards: Playground.initial_state()
     )}
  end

  @impl true
  def handle_event("change", %{"formatter" => formatter, "params" => params}, socket)
      when is_map(params) do
    case Map.fetch(@ids_by_string, formatter) do
      {:ok, id} ->
        previous = Map.fetch!(socket.assigns.cards, id)
        card = Playground.evaluate(id, params, previous)
        {:noreply, assign(socket, :cards, Map.put(socket.assigns.cards, id, card))}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("preset", %{"formatter" => formatter, "preset" => preset}, socket) do
    with {:ok, id} <- Map.fetch(@ids_by_string, formatter),
         true <- Enum.any?(Catalog.presets(id), &(&1.id == preset)) do
      previous = Map.fetch!(socket.assigns.cards, id)
      card = Playground.preset(id, preset, previous)
      {:noreply, assign(socket, :cards, Map.put(socket.assigns.cards, id, card))}
    else
      _unsupported_event -> {:noreply, socket}
    end
  end

  def handle_event("use-current-time", %{"formatter" => "relative_time"}, socket) do
    previous = Map.fetch!(socket.assigns.cards, :relative_time)
    card = Playground.use_current_time(previous, DateTime.utc_now())
    {:noreply, assign(socket, :cards, Map.put(socket.assigns.cards, :relative_time, card))}
  end

  def handle_event(_event, _params, socket), do: {:noreply, socket}
end
