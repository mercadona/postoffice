defmodule Postoffice.Repo.Migrations.AddInitialMessageToPublishers do
  use Ecto.Migration

  def change do
    alter table(:publishers) do
      add :initial_message, :integer
    end
  end
end
