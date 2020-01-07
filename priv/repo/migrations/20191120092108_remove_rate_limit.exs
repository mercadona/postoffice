defmodule Postoffice.Repo.Migrations.RemoveRateLimit do
  use Ecto.Migration

  def change do
    alter table(:publishers) do
      remove :rate_limit
    end
  end
end
