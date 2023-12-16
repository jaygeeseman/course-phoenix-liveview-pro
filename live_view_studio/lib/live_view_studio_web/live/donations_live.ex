defmodule LiveViewStudioWeb.DonationsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Donations

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(params, _, socket) do
    sort_by = (params["sort_by"] || "id") |> String.to_atom()
    sort_order = (params["sort_order"] || "asc") |> String.to_atom()

    {:noreply,
     assign(socket,
       donations: Donations.list_donations(%{sort_by: sort_by, sort_order: sort_order}),
       options: %{sort_by: sort_by, sort_order: sort_order}
     )}
  end

  attr :sort_by, :atom, default: nil
  attr :options, :map, required: true
  slot :inner_block

  def sort_link(assigns) do
    ~H"""
    <.link patch={
      ~p"/donations?#{%{sort_by: @sort_by, sort_order: link_sort_order(@options.sort_by, @sort_by, @options.sort_order)}}"
    }>
      <%= render_slot(@inner_block) %>
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
end
