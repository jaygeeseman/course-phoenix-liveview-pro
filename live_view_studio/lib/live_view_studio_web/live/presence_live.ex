defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:video"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @topic, current_user.id, %{
          username: current_user.email |> String.split("@") |> hd(),
          is_playing: false
        })
    end

    socket =
      socket
      |> assign(:is_playing, false)
      |> assign(:presences, simple_presence_map(Presence.list(@topic)))

    {:ok, socket}
  end

  def simple_presence_map(presences) do
    presences
    |> Enum.into(%{}, fn {user_id, user_data} -> {user_id, hd(user_data[:metas])} end)
  end

  def render(assigns) do
    ~H"""
    <pre><%#= inspect(@presences, pretty: true) %></pre>
    <div id="presence">
      <div class="users">
        <h2>Who's Here?</h2>
        <ul>
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
    {:noreply, socket}
  end
end
