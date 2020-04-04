defmodule Postoffice.Repo.Migrations.AddPendingMessageSchema do
  use Ecto.Migration

  def change do
    create table(:pending_messages) do
      add :publisher_id, references(:publishers), null: false
      add :message_id, references(:messages), null: false

      timestamps()
    end

    create unique_index(:pending_messages, [:publisher_id, :message_id], name: :index_publisher_and_message)
  end
end
