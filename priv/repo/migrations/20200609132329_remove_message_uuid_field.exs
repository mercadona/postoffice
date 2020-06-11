defmodule Postoffice.Repo.Migrations.RemoveMessageUuidField do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      remove :public_id
    end
  end
end
