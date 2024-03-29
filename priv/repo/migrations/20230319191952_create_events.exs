defmodule LiveForms.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :title, :string
      add :start_date, :date
      add :end_date, :date

      timestamps()
    end
  end
end
