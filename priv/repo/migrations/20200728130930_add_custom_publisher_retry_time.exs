defmodule Postoffice.Repo.Migrations.AddCustomPublisherRetryTime do
  use Ecto.Migration

  def change do
    alter table(:publishers) do
      add :seconds_retry, :integer, default: 5
    end
  end
end
