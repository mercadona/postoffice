defmodule Postoffice.Repo.Migrations.AddTopicSchema do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add :name, :string
      add :min_workers, :integer
      add :max_workers, :integer

      timestamps()
    end
  end
end
