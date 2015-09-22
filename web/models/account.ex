defmodule Entice.Web.Account do
  use Ecto.Model
  use Ecto.Model.Callbacks

  schema "accounts" do
    field :email, :string
    field :password, :string
    has_many :characters, Entice.Web.Character
    has_many :friends, Entice.Web.Friend
  end
end
