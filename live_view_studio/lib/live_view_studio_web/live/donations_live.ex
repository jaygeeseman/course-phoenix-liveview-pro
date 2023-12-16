defmodule LiveViewStudioWeb.DonationsLive do
  use LiveViewStudioWeb, :live_view

  alias LiveViewStudio.Donations

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [donations: []]}
  end

  def handle_params(params, _, socket) do
    sort_by = valid_sort_by(params)
    sort_order = valid_sort_order(params)

    {:noreply,
     assign(socket,
       donations: Donations.list_donations(%{sort_by: sort_by, sort_order: sort_order}),
       options: %{sort_by: sort_by, sort_order: sort_order}
     )}
  end

  attr :sort_by, :atom, required: true
  attr :options, :map, required: true
  slot :inner_block, required: true

  def sort_link(assigns) do
    ~H"""
    <.link patch={
      ~p"/donations?#{%{sort_by: @sort_by, sort_order: link_sort_order(@options.sort_by, @sort_by, @options.sort_order)}}"
    }>
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
