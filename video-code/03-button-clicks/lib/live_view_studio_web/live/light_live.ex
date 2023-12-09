defmodule LiveViewStudioWeb.LightLive do
  use LiveViewStudioWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket, brightness: 10)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Front Porch Light</h1>
    <div id="light">
      <div class="meter">
        <span style={"width: #{@brightness}%"}>
          <%= @brightness %>%
        </span>
      </div>
      <form phx-change="set">
        <input type="range" min="0" max="100"
              name="brightness" value={@brightness} />
      </form>
      <button phx-click="off">
        <img src="/images/light-off.svg" />
      </button>
      <button phx-click="down">
        <img src="/images/down.svg" />
      </button>
      <button phx-click="up">
        <img src="/images/up.svg" />
      </button>
      <button phx-click="on">
        <img src="/images/light-on.svg" />
      </button>
      <button phx-click="random">
        <img src="/images/fire.svg" />
      </button>
    </div>
    """
  end

  def handle_event("on", _, socket) do
    socket = assign(socket, brightness: 100)
    {:noreply, socket}
  end

  def handle_event("up", _, socket) do
    # More concise, but maybe harder to grok
    # socket = update(socket, :brightness, &min(&1 + 10, 100))
    socket =
      update(socket, :brightness, fn brightness ->
        # Increase by 10
        (brightness + 10)
        # but don't exceed 100
        |> min(100)
      end)

    {:noreply, socket}
  end

  def handle_event("down", _, socket) do
    # More concise, but maybe harder to grok
    # socket = update(socket, :brightness, &max(&1 - 10, 0))
    socket =
      update(socket, :brightness, fn brightness ->
        # Decrease by 10
        (brightness - 10)
        # but don't go below 0
        |> max(0)
      end)

    {:noreply, socket}
  end

  def handle_event("off", _, socket) do
    socket = assign(socket, brightness: 0)
    {:noreply, socket}
  end

  def handle_event("random", _, socket) do
    socket = assign(socket, :brightness, Enum.random(0..100))
    {:noreply, socket}
  end

  def handle_event("set", params, socket) do
    %{"brightness" => b} = params
    socket = assign(socket, :brightness, String.to_integer(b))
    {:noreply, socket}
  end
end
