defmodule LiveViewStudioWeb.DonationsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Donations

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [donations: []]}
  end

  def handle_params(params, _, socket) do
    options = %{
      sort_by: valid_sort_by(params),
      sort_order: valid_sort_order(params),
      page: (params["page"] || "1") |> String.to_integer(),
      per_page: (params["per_page"] || "5") |> String.to_integer()
    }

    # IO.inspect(options, label: "HANDLE_PARAMS options")

    {:noreply,
     assign(socket,
       donations: Donations.list_donations(options),
       options: options
     )}
  end

  def handle_event("select-per-page", %{"per-page" => per_page}, socket) do
    # Update the URL and send through push_patch to call handle_params from the server side rather than a link
    params = %{socket.assigns.options | per_page: (per_page || "5") |> String.to_integer()}
    socket = push_patch(socket, to: ~p"/donations?#{params}")
    {:noreply, socket}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    params = %{
      assigns.options
      | sort_by: assigns.sort_by,
        sort_order:
          link_sort_order(assigns.options.sort_by, assigns.sort_by, assigns.options.sort_order)
    }

    assigns = assign(assigns, params: params)

    ~H"""
    <.link patch={~p"/donations?#{@params}"}>
      <%= render_slot(@inner_block) %>
      <%= sort_indicator(@options.sort_by, @sort_by, @options.sort_order) %>
    </.link>
    """
  end

  defp link_sort_order(current_sort_by, link_sort_by, current_sort_order) do
    cond do
      # Change the order when clicking current sort_by column
      current_sort_by == link_sort_by && current_sort_order == :asc -> :desc
      # Default ascending
      true -> :asc
    end
  end

  defp sort_indicator(current_sort_by, link_sort_by, current_sort_order)
       when current_sort_by == link_sort_by do
    case current_sort_order do
      :asc -> "👆"
      :desc -> "👇"
    end
  end

  defp sort_indicator(_, _, _), do: ""

  defp valid_sort_by(%{"sort_by" => sort_by})
       when sort_by in ~w(item quantity days_until_expires) do
    String.to_atom(sort_by)
  end

  defp valid_sort_by(_params), do: :id

  defp valid_sort_order(%{"sort_order" => sort_order})
       when sort_order in ~w(asc desc) do
    String.to_atom(sort_order)
  end

  defp valid_sort_order(_params), do: :asc
end
