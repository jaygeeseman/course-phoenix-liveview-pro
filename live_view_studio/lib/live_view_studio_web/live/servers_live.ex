defmodule LiveViewStudioWeb.ServersLive do
  alias LiveViewStudioWeb.NewServerFormComponent
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Servers

  # As a general rule of thumb, if you have state that can change based on
  # URL parameters, then you should assign that state in handle_params.
  # Otherwise, any other state can be assigned in mount which is invoked
  # once per LiveView lifecycle.
  def mount(_params, _session, socket) do
    if connected?(socket), do: Servers.subscribe()

    {:ok,
     socket
     |> assign(
       servers: Servers.list_servers(),
       coffees: 0
     )}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    server = Servers.get_server!(id)

    {:noreply,
     socket
     |> assign(
       selected_server: server,
       page_title: server.name
     )}
  end

  def handle_params(_params, _uri, socket) do
    if socket.assigns.live_action == :new do
      {:noreply,
       socket
       |> assign(
         selected_server: nil,
         page_title: nil
       )}
    else
      {:noreply,
       socket
       |> assign(
         selected_server: hd(socket.assigns.servers),
         page_title: hd(socket.assigns.servers).name
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
            <.live_component module={NewServerFormComponent} id={:new} />
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
    {:noreply, socket |> update(:coffees, &(&1 + 1))}
  end

  def handle_event("cancel-server-create", _params, socket) do
    {:noreply, socket |> push_patch(to: ~p"/servers")}
  end

  def handle_event("toggle-server-status", %{"id" => id}, socket) do
    server = Servers.get_server!(id)
    {:ok, _} = Servers.toggle_status_server(server)

    {
      :noreply,
      socket
      # Display the updated server
      |> push_patch(to: ~p"/servers/#{server}")
    }
  end

  def handle_info({NewServerFormComponent, :new_server, server}, socket) do
    # Handles the local server created event. Displays the server that was just created
    {:noreply,
     socket
     # Display the server that was just added
     |> push_patch(to: ~p"/servers/#{server}")}
  end

  def handle_info({:server_created, server}, socket) do
    # Handles the universal server created event. Updates the server list.
    {:noreply,
     socket
     |> update(:servers, fn servers -> [server | servers] end)}
  end

  def handle_info({:server_updated, server}, socket) do
    socket =
      if socket.assigns.selected_server && server.id == socket.assigns.selected_server.id do
        push_patch(socket, to: ~p"/servers/#{server}")
      else
        socket
      end

    {
      :noreply,
      socket
      # TODO: Don't want to retrieve every time? Could change servers to stream
      |> assign(servers: Servers.list_servers())
    }
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
end
