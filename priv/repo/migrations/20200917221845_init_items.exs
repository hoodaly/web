defmodule Entice.Web.Repo.Migrations.InitItems do
  use Ecto.Migration

  def up do
    create table(:items, primary_key: false) do
      add :id,                :binary_id, primary_key: true
      add :name,              :string, size: 256
      add :model,             :string
      add :color,             {:array, :string}, default: []
      add :flags,             :string
      add :type,              :string
      add :stats,             {:array, :string}, default: []
      add :location,          :string
      add :account_id, references(:accounts, type: :binary_id)
      add :character_id, references(:characters, type: :binary_id)
      timestamps
    end
  end

  def down do
    drop table(:items)
  end
end
