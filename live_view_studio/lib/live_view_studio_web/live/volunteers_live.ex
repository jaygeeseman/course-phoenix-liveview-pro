defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer
  alias LiveViewStudioWeb.VolunteerFormComponent

  def mount(_params, _session, socket) do
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
        <button phx-click="toggle-checked-out" phx-value-id={@volunteer.id}>
          <%= if @volunteer.checked_out,
            do: "Check In",
            else: "Check Out" %>
        </button>
      </div>
      <.link
        class="delete"
        phx-click="delete"
        phx-value-id={@volunteer.id}
        data-confirm="Are you sure?"
      >
        <.icon name="hero-trash-solid" />
      </.link>
    </div>
    """
  end

  def handle_event("toggle-checked-out", %{"id" => id}, socket) do
    volunteer = Volunteers.get_volunteer!(id)

    {:ok, volunteer} =
      Volunteers.update_volunteer(volunteer, %{checked_out: !volunteer.checked_out})

    # Update UI - stream_insert also updates, like an upsert
    {:noreply,
     socket
     |> stream_insert(:volunteers, volunteer)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    volunteer = Volunteers.get_volunteer!(id)

    {:ok, _} = Volunteers.delete_volunteer(volunteer)

    {:noreply,
     socket
     |> update(:count, &(&1 - 1))
     |> stream_delete(:volunteers, volunteer)}
  end

  def handle_info({VolunteerFormComponent, :volunteer_created, volunteer}, socket) do
    {:noreply,
     socket
     |> update(:count, &(&1 + 1))
     |> stream_insert(:volunteers, volunteer, at: 0)}
  end
end
