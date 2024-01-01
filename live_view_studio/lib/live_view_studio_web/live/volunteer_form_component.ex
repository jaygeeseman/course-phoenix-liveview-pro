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

  # update is called in the lifecycle between mount and render,
  # and it receives assigns from the caller and allows us to perform
  # any needed manipulations before getting to render.
  # If not defined, default behavior is to merge assigns into
  # socket.assigns
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:count, assigns.count + 1)}
  end

  def render(assigns) do
    # Live components need a single static html tag at the root
    ~H"""
    <div>
      <div class="count">
        Go for it! You'll be volunteer #<%= @count %>
      </div>
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

      {:ok, _volunteer} ->
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
