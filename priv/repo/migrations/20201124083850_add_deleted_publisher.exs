defmodule Postoffice.Repo.Migrations.AddDeletedPublisher do
  use Ecto.Migration

  def change do
    alter table(:publishers) do
      add :deleted, :boolean, default: false
    end
  end
end
