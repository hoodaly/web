defmodule Entice.Web.VitalsChannel do
  use Entice.Web.Web, :channel
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Entice.Logic.{MapInstance, Vitals}
  alias Phoenix.Socket


  def join("vitals:" <> map, _message, %Socket{assigns: %{map: map_mod}} = socket) do
    %MapInstance{map: ^map_mod} = Entity.get_attribute(Entity.fetch!(map), MapInstance)
    Process.flag(:trap_exit, true)
    send(self(), :after_join)
    {:ok, socket}
  end


  def handle_info(:after_join, %Socket{assigns: %{entity_id: entity_id}} = socket) do
    Coordination.register_observer(self(), socket |> map_inst)
    Vitals.register(entity_id)
    {:noreply, socket}
  end


  def handle_info({:entity_dead, %{entity_id: entity_id}}, socket) do
    socket |> broadcast("entity:dead", %{entity: entity_id})
    {:noreply, socket}
  end


  def handle_info({:entity_resurrected, %{entity_id: entity_id}}, socket) do
    socket |> broadcast("entity:resurrected", %{entity: entity_id})
    {:noreply, socket}
  end


  def handle_info(_msg, socket), do: {:noreply, socket}


  def terminate(_msg, socket) do
    Vitals.unregister(socket |> entity_id)
    :ok
  end
end
