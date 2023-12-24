defmodule LiveViewStudioWeb.ServersLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers
  alias LiveViewStudio.Servers.Server

  # As a general rule of thumb, if you have state that can change based on
  # URL parameters, then you should assign that state in handle_params.
  # Otherwise, any other state can be assigned in mount which is invoked
  # once per LiveView lifecycle.
  def mount(_params, _session, socket) do
    servers = Servers.list_servers()

    socket =
      assign(socket,
        servers: servers,
        coffees: 0
      )

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    server = Servers.get_server!(id)

    {:noreply,
     assign(socket,
       selected_server: server,
       page_title: server.name,
       new_server_form: nil
     )}
  end

  def handle_params(_params, _uri, socket) do
    if socket.assigns.live_action == :new do
      {:noreply,
       assign(socket,
         selected_server: nil,
         page_title: nil,
         new_server_form: %Server{} |> Servers.change_server() |> to_form
       )}
    else
      {:noreply,
       assign(socket,
         selected_server: hd(socket.assigns.servers),
         page_title: hd(socket.assigns.servers).name,
         new_server_form: nil
       )}
    end
  end

  def render(assigns) do
    ~H"""
    <h1>Servers</h1>
    <div id="servers">
      <div class="sidebar">
        <div class="nav">
          <.link patch={~p"/servers/new"} class="add">
            + Add New Server
          </.link>
          <!-- `.link patch` meant for going to the same liveview and process -->
          <.link
            :for={server <- @servers}
            patch={~p"/servers/#{server}"}
            class={if server == @selected_server, do: "selected"}
          >
            <span class={server.status}></span>
            <%= server.name %>
          </.link>
        </div>
        <div class="coffees">
          <button phx-click="drink">
            <img src="/images/coffee.svg" />
            <%= @coffees %>
          </button>
        </div>
      </div>
      <div class="main">
        <div class="wrapper">
          <%= if @live_action == :new do %>
            <.new_server_form form={@new_server_form} />
          <% else %>
            <.server server={@selected_server} />
          <% end %>
          <div class="links">
            <!-- `.link navigate` meant for going to a different liveview -->
            <.link navigate={~p"/light"}>Adjust Lights</.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("drink", _, socket) do
    {:noreply, update(socket, :coffees, &(&1 + 1))}
  end

  def handle_event("server-create", %{"server" => server_params}, socket) do
    case Servers.create_server(server_params) do
      {:error, changeset} ->
        IO.inspect(changeset, label: "server-create error")

        {:noreply,
         assign(socket,
           new_server_form: changeset |> to_form
         )}

      {:ok, server} ->
        {:noreply,
         assign(socket,
           servers: [server | socket.assigns.servers],
           new_server_form: %Server{} |> Servers.change_server() |> to_form
         )
         # Display the server that was just added
         |> push_patch(to: ~p"/servers/#{server}")}
    end
  end

  def handle_event("validate-server-create", %{"server" => server_params}, socket) do
    {:noreply,
     assign(socket,
       new_server_form:
         %Server{}
         |> Servers.change_server(server_params)
         |> Map.put(:action, :validate)
         |> to_form
     )}
  end

  def handle_event("cancel-server-create", _params, socket) do
    {:noreply, socket |> push_patch(to: ~p"/servers")}
  end

  def handle_event("toggle-server-status", %{"id" => id}, socket) do
    server = Servers.get_server!(id)
    {:ok, _} = Servers.toggle_status_server(server)

    {:noreply,
     socket
     # TODO: Don't want to retrieve every time? Could change servers to stream
     |> assign(servers: Servers.list_servers())
     |> push_patch(to: ~p"/servers/#{server}")}
  end

  attr :server, :map, required: true

  def server(assigns) do
    ~H"""
    <div class="server">
      <div class="header">
        <h2><%= @server.name %></h2>
        <button
          class={@server.status}
          phx-click="toggle-server-status"
          phx-value-id={@server.id}
        >
          <%= @server.status %>
        </button>
      </div>
      <div class="body">
        <div class="row">
          <span>
            <%= @server.deploy_count %> deploys
          </span>
          <span>
            <%= @server.size %> MB
          </span>
          <span>
            <%= @server.framework %>
          </span>
        </div>
        <h3>Last Commit Message:</h3>
        <blockquote>
          <%= @server.last_commit_message %>
        </blockquote>
      </div>
    </div>
    """
  end

  def new_server_form(assigns) do
    ~H"""
    <div class="server">
      <.form
        for={@form}
        phx-submit="server-create"
        phx-change="validate-server-create"
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
end
