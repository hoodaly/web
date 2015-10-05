defmodule Entice.Web.MovementChannel do
  use Entice.Web.Web, :channel
  use Entice.Logic.Attributes
  alias Entice.Logic.Area
  alias Entice.Logic.Movement, as: Move
  alias Entice.Entity.Coordination
  alias Phoenix.Socket


  def join("movement:" <> map, _message, %Socket{assigns: %{map: map_mod}} = socket) do
    {:ok, ^map_mod} = Area.get_map(camelize(map))
    Process.flag(:trap_exit, true)
    send(self, :after_join)
    {:ok, socket}
  end


  def handle_info(:after_join, socket) do
    Coordination.register_observer(self)
    :ok = Move.register(socket |> entity_id)
    socket |> push("join:ok", %{})
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}


  # Incoming


  def handle_in("update", %{
      "pos" => %{"x" => pos_x, "y" => pos_y, "plane" => pos_plane} = pos,
      "goal" => %{"x" => goal_x, "y" => goal_y, "plane" => goal_plane} = goal,
      "move_type" => mtype,
      "velocity" => velo}, socket)
  when mtype in 0..10 and velo in -1..2 do
    Move.update(socket |> entity_id,
      %Position{pos: %Coord{x: pos_x, y: pos_y}, plane: pos_plane},
      %Movement{goal: %Coord{x: goal_x, y: goal_y}, plane: goal_plane, move_type: mtype, velocity: velo})

    broadcast!(socket, "update", %{entity: socket |> entity_id, pos: pos, goal: goal, move_type: mtype, velocity: velo})

    {:noreply, socket}
  end


  # Leaving the socket (voluntarily or forcefully)


  def terminate(_msg, socket) do
    Move.unregister(socket |> entity_id)
    :ok
  end
end

