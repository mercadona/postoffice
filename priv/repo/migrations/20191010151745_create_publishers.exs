defmodule Postoffice.Repo.Migrations.CreatePublishers do
  use Ecto.Migration

  def change do
    create table(:publishers) do
      add :endpoint, :string
      add :active, :boolean, default: false, null: false
      add :rate_limit, :integer
      add :type, :string
      add :topic_id, references(:topics), null: false

      timestamps()
    end
  end
end
