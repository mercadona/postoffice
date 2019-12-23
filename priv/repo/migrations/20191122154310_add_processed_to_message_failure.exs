defmodule Postoffice.Repo.Migrations.AddProcessedToMessageFailure do
  use Ecto.Migration

  def change do
    alter table(:publisher_failures) do
      add :processed, :boolean
    end
  end
end
