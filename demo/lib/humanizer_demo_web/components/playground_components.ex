defmodule HumanizerDemoWeb.PlaygroundComponents do
  @moduledoc false

  use HumanizerDemoWeb, :html

  attr :id, :atom, required: true
  attr :title, :string, required: true
  attr :signature, :string, required: true
  attr :description, :string, required: true
  attr :state, :map, required: true
  attr :presets, :list, required: true
  attr :class, :string, default: nil

  def formatter_card(assigns) do
    assigns = assign(assigns, :dom_id, Atom.to_string(assigns.id))

    ~H"""
    <article id={"formatter-#{@dom_id}"} class={["formatter-card", @class]}>
      <header class="formatter-card__header">
        <div>
          <p class="eyebrow">{@signature}</p>
          <h3>{@title}</h3>
          <p class="formatter-card__description">{@description}</p>
        </div>
        <span class="live-indicator"><span aria-hidden="true"></span> Live</span>
      </header>

      <form id={"form-#{@dom_id}"} phx-change="change" class="formatter-form">
        <input type="hidden" name="formatter" value={@dom_id} />
        <.controls id={@id} state={@state} />
      </form>

      <div class="result-panel">
        <span class="result-panel__label">Output</span>
        <output id={"result-#{@dom_id}"} class="result-panel__value">
          {@state.output || "—"}
        </output>
        <p :if={@state.errors["base"]} id={"#{@dom_id}-base-error"} class="field-error" role="alert">
          {@state.errors["base"]}
        </p>
      </div>

      <div class="code-panel">
        <div class="code-panel__bar">
          <span>Elixir</span>
          <button
            id={"copy-#{@dom_id}"}
            type="button"
            class="copy-button"
            phx-hook="CopyCode"
            data-copy-target={"code-#{@dom_id}"}
            aria-label={"Copy #{@signature} example"}
          >
            Copy
          </button>
        </div>
        <pre><code id={"code-#{@dom_id}"}>{@state.code || "Correct the highlighted field to generate code."}</code></pre>
      </div>

      <div class="preset-row" aria-label={"#{@title} presets"}>
        <button
          :for={preset <- @presets}
          type="button"
          phx-click="preset"
          phx-value-formatter={@dom_id}
          phx-value-preset={preset.id}
          data-preset={preset.id}
        >
          {preset.label}
        </button>
      </div>
    </article>
    """
  end

  attr :id, :atom, required: true
  attr :state, :map, required: true

  def controls(%{id: :bytes} = assigns) do
    ~H"""
    <div class="control-grid">
      <.field id={@id} state={@state} name="value" label="Byte count" inputmode="numeric" />
      <.select_field
        id={@id}
        state={@state}
        name="system"
        label="Unit system"
        options={[{"Decimal (SI)", "decimal"}, {"Binary (IEC)", "binary"}]}
      />
      <.field id={@id} state={@state} name="precision" label="Precision" inputmode="numeric" />
    </div>
    """
  end

  def controls(%{id: :number} = assigns) do
    ~H"""
    <div class="control-grid control-grid--two">
      <.field id={@id} state={@state} name="value" label="Number" inputmode="decimal" />
      <.field id={@id} state={@state} name="precision" label="Precision" inputmode="numeric" />
    </div>
    """
  end

  def controls(%{id: :percentage} = assigns) do
    ~H"""
    <p class="control-note">Ratios are the input: <code>1</code> becomes <code>100%</code>.</p>
    <div class="control-grid control-grid--two">
      <.field id={@id} state={@state} name="value" label="Ratio" inputmode="decimal" />
      <.field id={@id} state={@state} name="precision" label="Precision" inputmode="numeric" />
    </div>
    """
  end

  def controls(%{id: :delimit} = assigns) do
    ~H"""
    <div class="control-grid control-grid--two">
      <.field id={@id} state={@state} name="value" label="Number" inputmode="decimal" />
      <.field id={@id} state={@state} name="separator" label="Separator" />
    </div>
    <details class="advanced-options">
      <summary>Precision options</summary>
      <div class="control-grid control-grid--two">
        <.select_field
          id={@id}
          state={@state}
          name="precision_mode"
          label="Decimals"
          options={[{"Natural", "natural"}, {"Fixed", "fixed"}]}
        />
        <.field
          id={@id}
          state={@state}
          name="precision"
          label="Fixed precision"
          inputmode="numeric"
        />
      </div>
    </details>
    """
  end

  def controls(%{id: :ordinal} = assigns) do
    ~H"""
    <.field id={@id} state={@state} name="value" label="Whole number" inputmode="numeric" />
    """
  end

  def controls(%{id: :duration} = assigns) do
    ~H"""
    <div class="control-grid">
      <.field id={@id} state={@state} name="value" label="Seconds" inputmode="decimal" />
      <.select_field
        id={@id}
        state={@state}
        name="units"
        label="Units shown"
        options={[{"1", "1"}, {"2", "2"}, {"3", "3"}, {"4", "4"}, {"All", "all"}]}
      />
      <.select_field
        id={@id}
        state={@state}
        name="format"
        label="Format"
        options={[{"Long", "long"}, {"Short", "short"}]}
      />
    </div>
    """
  end

  def controls(%{id: :relative_time} = assigns) do
    ~H"""
    <div class="control-grid">
      <.field id={@id} state={@state} name="value" label="Value (UTC)" type="datetime-local" />
      <div class="field-with-action">
        <.field
          id={@id}
          state={@state}
          name="reference"
          label="Reference (UTC)"
          type="datetime-local"
        />
        <button
          type="button"
          class="field-action"
          phx-click="use-current-time"
          phx-value-formatter="relative_time"
          data-action="use-current-time"
        >
          Use current UTC time
        </button>
      </div>
      <.select_field
        id={@id}
        state={@state}
        name="format"
        label="Format"
        options={[{"Long", "long"}, {"Short", "short"}]}
      />
    </div>
    """
  end

  def controls(%{id: :truncate} = assigns) do
    ~H"""
    <.field id={@id} state={@state} name="text" label="Text" type="textarea" />
    <div class="control-grid">
      <.field id={@id} state={@state} name="length" label="Maximum length" inputmode="numeric" />
      <.field id={@id} state={@state} name="omission" label="Omission" />
      <.select_field
        id={@id}
        state={@state}
        name="break"
        label="Break at"
        options={[{"Character", "char"}, {"Word", "word"}]}
      />
    </div>
    """
  end

  def controls(%{id: :list_join} = assigns) do
    ~H"""
    <.field
      id={@id}
      state={@state}
      name="items"
      label="Items — one per line"
      type="textarea"
    />
    <div class="control-grid control-grid--two">
      <.field id={@id} state={@state} name="conjunction" label="Conjunction" />
      <.checkbox_field id={@id} state={@state} name="oxford" label="Oxford comma" />
    </div>
    <details class="advanced-options">
      <summary>Collapse options</summary>
      <div class="control-grid control-grid--two">
        <.checkbox_field id={@id} state={@state} name="max_enabled" label="Collapse long lists" />
        <.field id={@id} state={@state} name="max" label="Items shown" inputmode="numeric" />
        <.field id={@id} state={@state} name="other" label="Singular remainder" />
        <.field id={@id} state={@state} name="others" label="Plural remainder" />
      </div>
    </details>
    """
  end

  attr :id, :atom, required: true
  attr :state, :map, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :inputmode, :string, default: nil

  defp field(assigns) do
    assigns = field_assigns(assigns)

    ~H"""
    <div class="field">
      <label for={@input_id}>{@label}</label>
      <textarea
        :if={@type == "textarea"}
        id={@input_id}
        name={@input_name}
        aria-describedby={@error_id}
        aria-invalid={if(@error, do: "true", else: "false")}
        phx-debounce="180"
        rows="4"
      >{@value}</textarea>
      <input
        :if={@type != "textarea"}
        id={@input_id}
        name={@input_name}
        type={@type}
        value={@value}
        inputmode={@inputmode}
        aria-describedby={@error_id}
        aria-invalid={if(@error, do: "true", else: "false")}
        phx-debounce="180"
      />
      <.field_error id={@error_id} error={@error} />
    </div>
    """
  end

  attr :id, :atom, required: true
  attr :state, :map, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true
  attr :options, :list, required: true

  defp select_field(assigns) do
    assigns = field_assigns(assigns)

    ~H"""
    <div class="field">
      <label for={@input_id}>{@label}</label>
      <select
        id={@input_id}
        name={@input_name}
        aria-describedby={@error_id}
        aria-invalid={if(@error, do: "true", else: "false")}
      >
        <option :for={{label, value} <- @options} value={value} selected={@value == value}>
          {label}
        </option>
      </select>
      <.field_error id={@error_id} error={@error} />
    </div>
    """
  end

  attr :id, :atom, required: true
  attr :state, :map, required: true
  attr :name, :string, required: true
  attr :label, :string, required: true

  defp checkbox_field(assigns) do
    assigns = field_assigns(assigns)

    ~H"""
    <div class="field field--checkbox">
      <input type="hidden" name={@input_name} value="false" />
      <input
        id={@input_id}
        name={@input_name}
        type="checkbox"
        value="true"
        checked={@value == "true"}
        aria-describedby={@error_id}
        aria-invalid={@error != nil}
      />
      <label for={@input_id}>{@label}</label>
      <.field_error id={@error_id} error={@error} />
    </div>
    """
  end

  attr :id, :string, default: nil
  attr :error, :string, default: nil

  defp field_error(assigns) do
    ~H"""
    <p :if={@error} id={@id} class="field-error" role="alert">{@error}</p>
    """
  end

  defp field_assigns(assigns) do
    formatter = Atom.to_string(assigns.id)
    error = assigns.state.errors[assigns.name]

    assigns
    |> assign(:input_id, "#{formatter}-#{assigns.name}")
    |> assign(:input_name, "params[#{assigns.name}]")
    |> assign(:value, Map.get(assigns.state.params, assigns.name, ""))
    |> assign(:error, error)
    |> assign(:error_id, if(error, do: "#{formatter}-#{assigns.name}-error"))
  end
end
