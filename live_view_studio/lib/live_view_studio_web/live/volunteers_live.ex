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
        <%#= inspect(@form, pretty: true) %>
      </pre>

      <div id="volunteers" phx-update="stream">
        <div
          :for={{volunteer_id, volunteer} <- @streams.volunteers}
          class={"volunteer #{if volunteer.checked_out, do: "out"}"}
          id={volunteer_id}
        >
          <div class="name">
            <%= volunteer.name %>
          </div>
          <div class="phone">
            <%= volunteer.phone %>
          </div>
          <div class="status">
            <button>
              <%= if volunteer.checked_out,
                do: "Check In",
                else: "Check Out" %>
            </button>
          </div>
        </div>
      </div>
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
end
