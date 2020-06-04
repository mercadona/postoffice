defmodule Postoffice.Repo.Migrations.AddPublisherTimeout do
  use Ecto.Migration

  def change do
    alter table(:publishers) do
      add :seconds_timeout, :integer, default: 5
    end
  end
end
