defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence
  alias Phoenix.LiveView.JS

  @topic "users:video"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Presence.subscribe(@topic)
      Presence.track_user(current_user, @topic, %{is_playing: false})
    end

    {:ok,
     socket
     |> assign(
       is_playing: false,
       presences: Presence.list_users(@topic)
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="presence">
      <div class="users">
        <h2>
          Who's Here?
          <button phx-click={JS.toggle(to: "#presences")}>
            <.icon name="hero-list-bullet-solid" />
          </button>
        </h2>
        <ul id="presences">
          <li :for={{_user_id, user_data} <- @presences}>
            <span class="status">
              <%= if user_data.is_playing, do: "👀", else: "🙈" %>
            </span>
            <span class="username">
              <%= user_data.username %>
            </span>
          </li>
        </ul>
      </div>
      <div class="video" phx-click="toggle-playing">
        <%= if @is_playing do %>
          <.icon name="hero-pause-circle-solid" />
        <% else %>
          <.icon name="hero-play-circle-solid" />
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("toggle-playing", _, socket) do
    socket = update(socket, :is_playing, fn playing -> !playing end)

    Presence.update_user(socket.assigns.current_user, @topic, %{
      is_playing: socket.assigns.is_playing
    })

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    {:noreply, Presence.handle_diff(socket, diff)}
  end
end
