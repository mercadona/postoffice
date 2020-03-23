defmodule Postoffice.Repo.Migrations.AddFailureReason do
  use Ecto.Migration

  def change do
    alter table(:publisher_failures) do
      add :reason, :string 
    end
  end
end
