defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  # alias LiveViewStudio.Volunteers.Volunteer
  alias LiveViewStudioWeb.VolunteerFormComponent

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Volunteers.subscribe()
    end

    volunteers = Volunteers.list_volunteers()

    {:ok,
     socket
     # Streams allow managing large collections on the browser without keeping
     # the data in state on the server. See this commit for the requirements
     # versus assigns.
     |> stream(:volunteers, volunteers)
     |> assign(:count, length(volunteers))}
  end

  def render(assigns) do
    ~H"""
    <h1>Volunteer Check-In</h1>
    <div id="volunteer-checkin">
      <.live_component
        module={VolunteerFormComponent}
        id={:new}
        count={@count}
      />

      <pre>
        <%#= inspect(@form, pretty: true) %>
      </pre>

      <div id="volunteers" phx-update="stream">
        <.volunteer
          :for={{volunteer_id, volunteer} <- @streams.volunteers}
          volunteer={volunteer}
          id={volunteer_id}
        />
      </div>
    </div>
    """
  end

  def volunteer(assigns) do
    ~H"""
    <div
      class={"volunteer #{if @volunteer.checked_out, do: "out"}"}
      id={@id}
    >
      <div class="name">
        <%= @volunteer.name %>
      </div>
      <div class="phone">
        <%= @volunteer.phone %>
      </div>
      <div class="status">
        <button phx-click={toggle_checked_out(@id, @volunteer)}>
          <%= if @volunteer.checked_out, do: "Check In", else: "Check Out" %>
        </button>
      </div>
      <.link
        class="delete"
        phx-click={delete(@id, @volunteer)}
        data-confirm="Are you sure?"
      >
        <.icon name="hero-trash-solid" />
      </.link>
    </div>
    """
  end

  def handle_event("toggle-checked-out", %{"id" => id}, socket) do
    volunteer = Volunteers.get_volunteer!(id)

    {:ok, _volunteer} =
      Volunteers.update_volunteer(volunteer, %{checked_out: !volunteer.checked_out})

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = Volunteers.get_volunteer!(id) |> Volunteers.delete_volunteer()

    {:noreply, socket}
  end

  def handle_info({:volunteer_created, volunteer}, socket) do
    {:noreply,
     socket
     |> update(:count, &(&1 + 1))
     |> stream_insert(:volunteers, volunteer, at: 0)}
  end

  def handle_info({:volunteer_updated, volunteer}, socket) do
    {:noreply,
     socket
     # stream_insert also updates, like an upsert
     |> stream_insert(:volunteers, volunteer)}
  end

  def handle_info({:volunteer_deleted, volunteer}, socket) do
    {:noreply,
     socket
     |> update(:count, &(&1 - 1))
     |> stream_delete(:volunteers, volunteer)}
  end

  def toggle_checked_out(volunteer_id, volunteer) do
    JS.push("toggle-checked-out", value: %{id: volunteer.id})
    |> JS.transition("shake", to: "##{volunteer_id}", time: 500)
  end

  def delete(volunteer_id, volunteer) do
    JS.push("delete", value: %{id: volunteer.id})
    |> JS.hide(
      to: "##{volunteer_id}",
      transition: "ease duration-1000 scale-150 opacity-0",
      time: 1000
    )
  end
end
