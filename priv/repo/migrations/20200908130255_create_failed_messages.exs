defmodule Postoffice.Repo.Migrations.CreateFailedMessages do
  use Ecto.Migration

  def change do
    create table(:failed_messages) do
      add :consumer_id, :integer
      add :message_id, :integer
      add :payload, :map
      add :attributes, :map
      add :reason, :string

      timestamps()
    end

  end
end
