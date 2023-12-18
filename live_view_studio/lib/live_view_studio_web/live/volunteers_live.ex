defmodule LiveViewStudioWeb.VolunteersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       volunteers: Volunteers.list_volunteers(),
       # This magic makes forms easy ✨✨
       form: %Volunteer{} |> Volunteers.change_volunteer() |> to_form
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Volunteer Check-In</h1>
    <div id="volunteer-checkin">
      <.form
        for={@form}
        phx-submit="check-in"
        phx-change="validate-check-in"
      >
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

      <pre>
        <%= inspect(@form, pretty: true) %>
      </pre>

      <div
        :for={volunteer <- @volunteers}
        class={"volunteer #{if volunteer.checked_out, do: "out"}"}
      >
        <div class="name">
          <%= volunteer.name %>
        </div>
        <div class="phone">
          <%= volunteer.phone %>
        </div>
        <div class="status">
          <button>
            <%= if volunteer.checked_out, do: "Check In", else: "Check Out" %>
          </button>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("check-in", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:error, changeset} ->
        # changeset |> to_form ✨✨
        {:noreply, assign(socket, form: changeset |> to_form)}

      {:ok, volunteer} ->
        {:noreply,
         assign(socket,
           # volunteers: Volunteers.list_volunteers(),
           # Do this to not hit the db again (but I worry about getting out of sync)
           volunteers: [volunteer | socket.assigns.volunteers],
           form: %Volunteer{} |> Volunteers.change_volunteer() |> to_form
         )
         |> put_flash(:info, "Thank you for checking in!")}
    end
  end

  def handle_event("validate-check-in", %{"volunteer" => volunteer_params}, socket) do
    {:noreply,
     assign(socket,
       form:
         %Volunteer{}
         |> Volunteers.change_volunteer(volunteer_params)
         |> Map.put(:action, :validate)
         |> to_form
     )}
  end
end
