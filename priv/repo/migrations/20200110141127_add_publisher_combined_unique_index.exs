defmodule Postoffice.Repo.Migrations.AddPublisherCombinedUniqueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:publishers, [:topic_id, :endpoint, :type])
  end
end
