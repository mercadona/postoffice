defmodule Postoffice.Repo.Migrations.CreatePublisherSuccesss do
  use Ecto.Migration

  def change do
    create table(:publisher_success) do
      add :message_id, references(:messages), null: false
      add :publisher_id, references(:publishers), null: false

      timestamps()
    end
  end
end
