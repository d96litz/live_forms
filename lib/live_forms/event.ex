defmodule LiveForms.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :end_date, :date
    field :start_date, :date
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:title, :start_date, :end_date])
    |> validate_required([:title, :start_date, :end_date])
  end
end
