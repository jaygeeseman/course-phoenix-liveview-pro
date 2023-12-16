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
       sort_by: sort_by,
       sort_order: sort_order
     )}
  end

  def link_sort_order(current_sort_by, link_sort_by, current_sort_order) do
    cond do
      # Change the order when clicking current sort_by column
      current_sort_by == link_sort_by && current_sort_order == :asc -> :desc
      # Default ascending
      true -> :asc
    end
  end
end
