defmodule Postoffice.Repo.Migrations.AddPublisherChunkSize do
  use Ecto.Migration

  def change do
    alter table(:publishers) do
      add :chunk_size, :integer, default: nil
    end
  end
end
