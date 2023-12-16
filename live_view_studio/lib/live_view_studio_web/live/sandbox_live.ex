defmodule LiveViewStudioWeb.SandboxLive do
  use LiveViewStudioWeb, :live_view

  import Number.Currency
  alias LiveViewStudio.Sandbox

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        length: "0",
        width: "0",
        depth: "0",
        weight: 0.0,
        price: nil
      )

    {:ok, socket}
  end

  def handle_event("change_size", params, socket) do
    %{"length" => l, "width" => w, "depth" => d} = params

    socket =
      assign(
        socket,
        length: l,
        width: w,
        depth: d,
        weight: Sandbox.calculate_weight(l, w, d),
        price: nil
      )

    {:noreply, socket}
  end

  def handle_event("get_a_quote", _, socket) do
    socket =
      assign(socket, price: Sandbox.calculate_price(socket.assigns.weight))

    {:noreply, socket}
  end
end
