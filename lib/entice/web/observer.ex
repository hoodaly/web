defmodule Entice.Web.Observer do
  @moduledoc """
  Report changes to certain attributes of an entity back to a certain topic.
  """
  alias Entice.Entity
  alias Entice.Web.Observer


  # Outside API


  def init(entity_id) do
    if not (entity_id |> Entity.has_behaviour?(Observer.Behaviour)),
    do: Entity.put_behaviour(entity_id, Observer.Behaviour, [])
  end


  def notify_active(entity_id, topic, attribute_types),
  do: Entity.notify(entity_id, {:observer_active, topic, attribute_types})


  def notify_inactive(entity_id, topic),
  do: Entity.notify(entity_id, {:observer_inactive, topic})


  def remove(entity_id),
  do: Entity.remove_behaviour(entity_id, Observer.Behaviour)


  # Behaviour internals


  defmodule Behaviour do
    use Entice.Entity.Behaviour
    use Entice.Logic.Attributes


    def init(id, attributes, _args), do: {:ok, attributes, %{entity_id: id, reporters: %{}}}


    def handle_event({:observer_active, topic, attribute_types}, attributes, %{entity_id: id, reporters: reporters}) do
      reporters = reporters |> Map.put(topic, attribute_types)
      report(id, reporters, attributes)

      {:ok, attributes, %{entity_id: id, reporters: reporters}}
    end


    def handle_event({:observer_inactive, topic}, attributes, %{entity_id: id, reporters: reporters}) do
      reporters = reporters |> Map.delete(topic)
      {:ok, attributes, %{entity_id: id, reporters: reporters}}
    end


    def handle_attributes_changed(old, attributes, %{entity_id: id, reporters: reporters} = state) do
      report(id, reporters, attributes)
      report_missing(id, reporters, old, attributes)
      {:ok, attributes, state}
    end


    # Internal


    defp report(entity_id, reporters, attributes) do
      for (topic <- reporters |> Map.keys) do
        if (reporters[topic] |> Enum.all?(fn attr -> attributes |> Map.has_key?(attr) end)) do
          reporters[topic]
          |> Enum.reduce(%{}, fn (attr, acc) -> acc |> Map.put(attr, attributes[attr]) end)
          |> (&(if not Enum.empty?(&1),
                do: Entice.Web.Endpoint.broadcast(topic, "observed", %{entity_id: entity_id, attributes: &1}))).()
        end
      end
    end

    defp report_missing(entity_id, reporters, attrs_before, attrs_after) do
      for (topic <- reporters |> Map.keys) do
        reporters[topic]
        |> Enum.filter(fn attr -> (attrs_before |> Map.has_key?(attr)) and not (attrs_after |> Map.has_key?(attr)) end)
        |> (&(if not Enum.empty?(&1),
              do: Entice.Web.Endpoint.broadcast(topic, "missed", %{entity_id: entity_id, attributes: &1}))).()
      end
    end
  end
end