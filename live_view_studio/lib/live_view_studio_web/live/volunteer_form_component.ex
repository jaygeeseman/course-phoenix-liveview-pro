defmodule LiveViewStudioWeb.VolunteerFormComponent do
  use LiveViewStudioWeb, :live_component

  alias LiveViewStudio.Volunteers
  alias LiveViewStudio.Volunteers.Volunteer

  def mount(socket) do
    {:ok,
     socket
     |> assign(
       # This magic makes forms easy ✨✨
       form: %Volunteer{} |> Volunteers.change_volunteer() |> to_form
     )}
  end

  def render(assigns) do
    # Live components need a single static html tag at the root
    ~H"""
    <div>
      <.form
        for={@form}
        phx-submit="check-in"
        phx-change="validate-check-in"
        phx-target={@myself}
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
    </div>
    """
  end

  def handle_event("check-in", %{"volunteer" => volunteer_params}, socket) do
    case Volunteers.create_volunteer(volunteer_params) do
      {:error, changeset} ->
        # changeset |> to_form ✨✨
        {:noreply, socket |> assign(form: changeset |> to_form)}

      {:ok, volunteer} ->
        # Notify parent liveview that the volunteer was created
        send(self(), {:volunteer_created, volunteer})

        {:noreply,
         socket
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
