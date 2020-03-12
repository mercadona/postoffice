defmodule Postoffice.Repo.Migrations.AddRecoveryEnabledToTopic do
  use Ecto.Migration

  def change do
    alter table(:topics) do
      add :recovery_enabled, :boolean, default: false
    end
  end
end
