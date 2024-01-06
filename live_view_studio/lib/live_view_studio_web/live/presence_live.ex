defmodule LiveViewStudioWeb.PresenceLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:video"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Phoenix.PubSub.subscribe(LiveViewStudio.PubSub, @topic)

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

    %{current_user: current_user} = socket.assigns
    # `[meta | _]` pattern matches the first element in a list, so it can get
    # only the first element of {%metas: [item1, item2, ...]}
    # %{metas: [meta | _]} = Presence.get_by_key(@topic, current_user.id)

    # ^ `hd` does the same thing and is easier to grok
    meta = Presence.get_by_key(@topic, current_user.id).metas |> hd
    new_meta = %{meta | is_playing: socket.assigns.is_playing}

    Presence.update(self(), @topic, current_user.id, new_meta)

    {:noreply, socket}
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    socket =
      socket
      |> remove_presences(diff.leaves)
      |> add_presences(diff.joins)

    # Simpler to code, but likely less efficient
    # |> assign(:presences, simple_presence_map(Presence.list(@topic)))

    {:noreply, socket}
  end

  defp add_presences(socket, joins) do
    socket
    |> assign(
      :presences,
      socket.assigns.presences
      |> Map.merge(joins |> simple_presence_map)
    )
  end

  defp remove_presences(socket, leaves) do
    socket
    |> assign(
      :presences,
      socket.assigns.presences
      # |> Map.reject(fn {k, _} -> Map.has_key?(leaves, k) end)
      # This may perform better with a large presence list
      |> Map.drop(leaves |> Enum.map(fn {user_id, _} -> user_id end))
    )
  end
end
