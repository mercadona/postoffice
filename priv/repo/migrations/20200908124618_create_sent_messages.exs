defmodule Postoffice.Repo.Migrations.CreateSentMessages do
  use Ecto.Migration

  def change do
    create table(:sent_messages) do
      add :consumer_id, :integer
      add :message_id, :integer
      add :payload, :map
      add :attributes, :map

      timestamps()
    end
  end
end
