defmodule Postoffice.Repo.Migrations.AddTopicSchema do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string

      timestamps()
    end
  end
end
