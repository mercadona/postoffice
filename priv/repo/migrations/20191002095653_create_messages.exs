defmodule Postoffice.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :public_id, :uuid
      add :payload, :jsonb
      # add :topic, :string
      add :topic_id, references(:topics), null: false
      add :attributes, :map

      timestamps()
    end
  end
end
