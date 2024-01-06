defmodule LiveViewStudioWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :live_view_studio,
    pubsub_server: LiveViewStudio.PubSub

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(LiveViewStudio.PubSub, topic)
  end

  def track_user(user, topic, meta) do
    {:ok, _} =
      track(
        self(),
        topic,
        user.id,
        user |> merge_meta(meta)
      )
  end

  def list_users(topic) do
    simple_presence_map(list(topic))
  end

  def update_user(user, topic, meta) do
    # `[meta | _]` pattern matches the first element in a list, so it can get
    # only the first element of {%metas: [item1, item2, ...]}
    # %{metas: [meta | _]} = get_by_key(topic, user.id) |> Map.merge(meta)

    # ^ `hd` does the same thing and is easier to grok
    user_meta =
      get_by_key(topic, user.id).metas
      |> hd
      |> Map.merge(meta)

    update(self(), topic, user.id, user |> merge_meta(user_meta))
  end

  def handle_diff(socket, diff) do
    socket
    |> remove_presences(diff.leaves)
    |> add_presences(diff.joins)

    # Simpler to code, but likely less efficient
    # |> assign(:presences, Presence.simple_presence_map(Presence.list(@topic)))
  end

  defp add_presences(socket, joins) do
    socket
    |> Phoenix.Component.assign(
      :presences,
      socket.assigns.presences
      |> Map.merge(joins |> simple_presence_map())
    )
  end

  defp remove_presences(socket, leaves) do
    socket
    |> Phoenix.Component.assign(
      :presences,
      socket.assigns.presences
      |> Map.drop(leaves |> Map.keys())
    )
  end

  defp simple_presence_map(presences) do
    presences
    |> Enum.into(%{}, fn {user_id, user_data} -> {user_id, hd(user_data[:metas])} end)
  end

  defp merge_meta(user, meta) do
    meta
    |> Map.merge(%{username: user.email |> String.split("@") |> hd()})
  end
end
