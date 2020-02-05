defmodule Postoffice.Repo.Migrations.RecreateUniqueIndexInPublisherWithTarget do
  use Ecto.Migration

  def change do
    drop unique_index(:publishers, [:topic_id, :endpoint, :type])
    create unique_index(:publishers, [:topic_id, :target, :type])
  end
end
