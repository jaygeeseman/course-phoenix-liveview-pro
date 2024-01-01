defmodule LiveViewStudioWeb.NewServerFormComponent do
  use LiveViewStudioWeb, :live_component

  alias LiveViewStudio.Servers
  alias LiveViewStudio.Servers.Server

  def mount(socket) do
    {:ok,
     socket
     |> assign(form: %Server{} |> Servers.change_server() |> to_form)}
  end

  def render(assigns) do
    ~H"""
    <div class="server">
      <.form
        for={@form}
        phx-submit="server-create"
        phx-change="validate-server-create"
        phx-target={@myself}
      >
        <div class="field">
          <label for="server_name">Server Name</label>
          <.input
            field={@form[:name]}
            autocomplete="off"
            phx-debounce="1500"
          />
        </div>
        <div class="field">
          <label for="server_framework">Framework</label>
          <.input field={@form[:framework]} phx-debounce="1500" />
        </div>
        <div class="field">
          <label for="server_size">Size in MB</label>
          <.input
            field={@form[:size]}
            type="number"
            step="any"
            phx-debounce="blur"
          />
        </div>
        <.button phx-disable-with="Saving...">
          Add Server
        </.button>
        <.link phx-click="cancel-server-create" class="cancel">
          Cancel
        </.link>
      </.form>
    </div>
    """
  end

  def handle_event("server-create", %{"server" => server_params}, socket) do
    case Servers.create_server(server_params) do
      {:error, changeset} ->
        IO.inspect(changeset, label: "server-create error")

        {:noreply,
         socket
         |> assign(form: changeset |> to_form)}

      {:ok, server} ->
        self() |> send({__MODULE__, :new_server, server})

        {:noreply,
         socket
         |> assign(form: %Server{} |> Servers.change_server() |> to_form)}
    end
  end

  def handle_event("validate-server-create", %{"server" => server_params}, socket) do
    {:noreply,
     socket
     |> assign(
       form:
         %Server{}
         |> Servers.change_server(server_params)
         |> Map.put(:action, :validate)
         |> to_form
     )}
  end
end
