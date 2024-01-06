defmodule LiveViewStudioWeb.BingoLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudioWeb.Presence

  @topic "users:bingo"

  def mount(_params, _session, socket) do
    %{current_user: current_user} = socket.assigns

    if connected?(socket) do
      Presence.subscribe(@topic)

      Presence.track_user(current_user, @topic, %{
        join_time: Timex.now() |> Timex.format!("%H:%M", :strftime)
      })

      # send message to trigger a refresh every 3 seconds
      :timer.send_interval(3000, self(), :tick)
    end

    {:ok,
     socket
     |> assign(
       number: nil,
       numbers: all_numbers(),
       presences: Presence.list_users(@topic)
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Bingo Boss 📢</h1>
    <div>
      Current user: <%= @current_user.email |> String.split("@") |> hd() %>
    </div>
    <div id="bingo">
      <div class="users">
        <ul>
          <li :for={{_user_id, user_data} <- @presences}>
            <span class="username">
              <%= user_data.username %>
            </span>
            <span class="timestamp">
              20:50
            </span>
          </li>
        </ul>
      </div>

      <div class="number">
        <%= @number %>
      </div>
    </div>
    """
  end

  def handle_info(%{event: "presence_diff", payload: diff}, socket) do
    {:noreply, Presence.handle_diff(socket, diff)}
  end

  def handle_info(:tick, socket) do
    {:noreply, pick(socket)}
  end

  # Assigns the next random bingo number, removing it
  # from the assigned list of numbers. Resets the list
  # when the last number has been picked.
  defp pick(socket) do
    case socket.assigns.numbers do
      [head | []] ->
        assign(socket, number: head, numbers: all_numbers())

      [head | tail] ->
        assign(socket, number: head, numbers: tail)
    end
  end

  # Returns a list of all valid bingo numbers in random order.
  #
  # Example: ["B 4", "N 40", "O 73", "I 29", ...]
  defp all_numbers() do
    ~w(B I N G O)
    |> Enum.zip(Enum.chunk_every(1..75, 15))
    |> Enum.flat_map(fn {letter, numbers} ->
      Enum.map(numbers, &"#{letter} #{&1}")
    end)
    |> Enum.shuffle()
  end
end
