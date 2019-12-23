defmodule Postoffice.Repo.Migrations.CreatePublisherFaillures do
  use Ecto.Migration

  def change do
    create table(:publisher_failures) do
      add :message_id, references(:messages), null: false
      add :publisher_id, references(:publishers), null: false

      timestamps()
    end
  end
end
