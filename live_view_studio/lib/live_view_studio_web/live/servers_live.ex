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
        new_server_form: %Server{} |> Servers.change_server() |> to_form,
        coffees: 0
      )

    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    server = Servers.get_server!(id)

    {:noreply,
     assign(socket,
       selected_server: server,
       page_title: server.name
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply,
     assign(socket,
       selected_server: hd(socket.assigns.servers),
       page_title: hd(socket.assigns.servers).name
     )}
  end

  def render(assigns) do
    ~H"""
    <h1>Servers</h1>
    <div id="servers">
      <div class="sidebar">
        <div class="nav">
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
          <div>
            <.form for={@new_server_form} phx-submit="server-create">
              <div class="field">
                <label for="server_name">Server Name</label>
                <.input field={@new_server_form[:name]} autocomplete="off" />
              </div>
              <div class="field">
                <label for="server_framework">Framework</label>
                <.input field={@new_server_form[:framework]} />
              </div>
              <div class="field">
                <label for="server_size">Size in MB</label>
                <.input
                  field={@new_server_form[:size]}
                  type="number"
                  step="any"
                />
              </div>
              <.button phx-disable-with="Saving...">
                Add Server
              </.button>
            </.form>
          </div>

          <.server server={@selected_server} />
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
         |> push_patch(to: ~p"/servers?#{server}")}
    end
  end

  attr :server, :map, required: true

  def server(assigns) do
    ~H"""
    <div class="server">
      <div class="header">
        <h2><%= @server.name %></h2>
        <span class={@server.status}>
          <%= @server.status %>
        </span>
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
