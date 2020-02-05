defmodule Postoffice.Repo.Migrations.AddOriginHostToTopic do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :origin_host, :string, null: true
    end
  end
end
