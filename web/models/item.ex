defmodule Entice.Web.Item do
  use Entice.Web.Web, :schema

  schema "items" do
    field       :name,           :string
    field       :model,          :string
    field       :color,          {:array, :string}
    field       :flags,          {:array, :string}
    field       :stats,          {:array, :string}
    field       :type,           :string
    field       :location,       :string
    belongs_to  :account,        Entice.Web.Account
    belongs_to  :character,      Entice.Web.Character
    timestamps()
  end


  def changeset(item, params \\ :invalid) do
    item
    |> cast(params, [:name, :model, :color, :flags, :stats, :type, :location, :account_id, :character_id])
    |> validate_required([:name, :model, :color, :flags, :stats, :type, :location, :account_id, :character_id])
    |> assoc_constraint(:account)
    |> assoc_constraint(:character)
  end
end
