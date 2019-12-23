defmodule Postoffice.Repo.Migrations.AddIndexOnMessagesUuid do
  use Ecto.Migration

  def change do
    create index("messages", [:public_id], unique: true, name: "unique_uuids")
  end
end
