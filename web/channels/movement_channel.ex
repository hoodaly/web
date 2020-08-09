defmodule Entice.Web.MovementChannel do
  use Entice.Web.Web, :channel
  use Entice.Logic.Attributes
  alias Entice.Logic.Maps
  alias Entice.Logic.Movement, as: Move
  alias Entice.Entity
  alias Entice.Entity.Coordination
  alias Phoenix.Socket
  alias Geom.Shape.Vector2D


  def join("movement:" <> map, _message, %Socket{assigns: %{map: map_mod}} = socket) do
    {:ok, ^map_mod} = Maps.get_map(camelize(map))
    Process.flag(:trap_exit, true)
    send(self(), :after_join)
    {:ok, socket}
  end


  def handle_info(:after_join, socket) do
    Coordination.register_observer(self(), socket |> map)
    :ok = Move.register(socket |> entity_id)
    {:noreply, socket}
  end

  # info that something other than the client changed the position
  def handle_info({:entity_change, %{changed: %{Position => %Position{coord: pos, plane: plane}}, entity_id: moving_entity_id}}, socket) do
    %Move{goal: goal, velocity: velocity, move_type: move_type} = Entity.get_attribute(moving_entity_id, Movement)
    broadcast!(socket, "update", %{
      entity: moving_entity_id,
      position: %{"x" => pos.x, "y" => pos.y, "plane" => plane},
      goal: %{"x" => goal.x, "y" => goal.y},
      velocity: velocity,
      move_type: move_type
    })
    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}


  # Incoming

  # Info that something other than the client changed the position
  def handle_in("update", %{"entity" => _}, socket), do: {:noreply, socket}

  # Notice from the client that an entity position has changed
  def handle_in("update", %{
      "position" => %{"x" => pos_x, "y" => pos_y, "plane" => pos_plane} = pos,
      "goal" => %{"x" => goal_x, "y" => goal_y, "plane" => goal_plane} = goal,
      "move_type" => mtype,
      "velocity" => velo}, socket)
  when mtype in 0..10 and (-1.0 < velo) and (velo < 2.0) do
    Move.update(socket |> entity_id,
      %Position{coord: %Vector2D{x: pos_x, y: pos_y}, plane: pos_plane},
      %Movement{goal: %Vector2D{x: goal_x, y: goal_y}, plane: goal_plane, move_type: mtype, velocity: velo})

    broadcast!(socket, "update", %{entity: socket |> entity_id, position: pos, goal: goal, move_type: mtype, velocity: velo})

    {:noreply, socket}
  end


  # Leaving the socket (voluntarily or forcefully)


  def terminate(_msg, socket) do
    Move.unregister(socket |> entity_id)
    :ok
  end
end

