defmodule Postoffice.Repo.Migrations.AddPendingMessageSchema do
  use Ecto.Migration

  def change do
    create table(:pending_messages) do
      add :topic_id, references(:topics), null: false
      add :message_id, references(:messages), null: false

      timestamps()
    end

  end
end
