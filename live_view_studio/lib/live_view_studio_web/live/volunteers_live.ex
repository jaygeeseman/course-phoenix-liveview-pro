defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(_params, _session, socket) do
    {:ok,
     socket
     # Streams allow managing large collections on the browser without keeping
     # the data in state on the server. See this commit for the requirements
     # versus assigns.
     |> stream(:volunteers, Volunteers.list_volunteers())
     |> assign(
       # This magic makes forms easy ✨✨
       form: %Volunteer{} |> Volunteers.change_volunteer() |> to_form
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Volunteer Check-In</h1>
    <div id="volunteer-checkin">
      <.checkin_form form={@form} />

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

  def checkin_form(assigns) do
    ~H"""
    <.form for={@form} phx-submit="check-in" phx-change="validate-check-in">
      <.input
        field={@form[:name]}
        placeholder="Name"
        autocomplete="off"
        phx-debounce="2000"
      />
      <.input
        field={@form[:phone]}
        type="tel"
        placeholder="Phone"
        autocomplete="off"
        phx-debounce="blur"
      />
      <.button phx-disable-with="Saving...">
        Check In
      </.button>
    </.form>
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

  def handle_event("check-in", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:error, changeset} ->
        # changeset |> to_form ✨✨
        {:noreply, socket |> assign(form: changeset |> to_form)}

      {:ok, volunteer} ->
        {:noreply,
         socket
         |> stream_insert(:volunteers, volunteer, at: 0)
         |> assign(form: %Volunteer{} |> Volunteers.change_volunteer() |> to_form)
         |> put_flash(:info, "Thank you for checking in!")}
    end
  end

  def handle_event("validate-check-in", %{"volunteer" => volunteer_params}, socket) do
    {:noreply,
     socket
     |> assign(
       form:
         %Volunteer{}
         |> Volunteers.change_volunteer(volunteer_params)
         |> Map.put(:action, :validate)
         |> to_form
     )}
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
     |> stream_delete(:volunteers, volunteer)}
  end
end
