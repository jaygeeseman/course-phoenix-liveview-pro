defmodule LiveViewStudioWeb.BoatsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Boats

  # import allows us to continue using <.promo>
  # alias would require <CustomComponents.promo> instead
  import LiveViewStudioWeb.CustomComponents

  def mount(_params, _session, socket) do
    # Boats array not needed in state, so clear after each render
    {:ok, socket, temporary_assigns: [boats: []]}
  end

  def render(assigns) do
    ~H"""
    <h1>Daily Boat Rentals</h1>
    <.promo expiration={2}>
      Save 25% on rentals!
      <:legal>
        <.icon name="hero-exclamation-circle" /> Limit 1 per party
      </:legal>
    </.promo>
    <div id="boats">
      <.filter_form filter={@filter} />

      <div class="boats">
        <.boat :for={boat <- @boats} boat={boat} />
      </div>
    </div>
    <.promo>
      Hurry, only 3 boats left!
    </.promo>
    """
  end

  attr :filter, :map, required: true

  def filter_form(assigns) do
    ~H"""
    <form phx-change="update-filter">
      <div class="filters">
        <select name="type">
          <%= Phoenix.HTML.Form.options_for_select(
            type_options(),
            @filter.type
          ) %>
        </select>
        <div class="prices">
          <%= for price <- ["$", "$$", "$$$"] do %>
            <input
              type="checkbox"
              name="prices[]"
              value={price}
              id={price}
              checked={price in @filter.prices}
            />
            <label for={price}><%= price %></label>
          <% end %>
          <input type="hidden" name="prices[]" value="" />
        </div>
      </div>
    </form>
    """
  end

  attr :boat, LiveViewStudio.Boats.Boat, required: true

  def boat(assigns) do
    ~H"""
    <div class="boat">
      <img src={@boat.image} />
      <div class="content">
        <div class="model">
          <%= @boat.model %>
        </div>
        <div class="details">
          <span class="price">
            <%= @boat.price %>
          </span>
          <span class="type">
            <%= @boat.type %>
          </span>
        </div>
      </div>
    </div>
    """
  end

  def handle_params(params, _, socket) do
    filter = %{type: params["type"] || "", prices: params["prices"] || []}

    socket =
      assign(socket,
        filter: filter,
        boats: Boats.list_boats(filter)
      )

    {:noreply, socket}
  end

  def handle_event("update-filter", %{"type" => type, "prices" => prices}, socket) do
    filter = %{type: type, prices: prices}
    socket = push_patch(socket, to: ~p"/boats?#{filter}")

    {:noreply, socket}
  end

  defp type_options do
    [
      "All Types": "",
      Fishing: "fishing",
      Sporting: "sporting",
      Sailing: "sailing"
    ]
  end
end
