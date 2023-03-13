defmodule LiveForms.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveForms.Repo

  schema "users" do
    field :bio, :string
    field :email, :string
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :bio])
    |> validate_required([:name, :email, :bio])
    |> validate_format(:email, ~r/^\w+@\w+\.[a-z]{2,3}$/)
    |> validate_length(:bio, min: 5)
    |> unsafe_validate_unique(:email, Repo)
  end
end
