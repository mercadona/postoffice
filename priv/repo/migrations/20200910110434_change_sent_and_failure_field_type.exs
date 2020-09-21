defmodule Postoffice.Repo.Migrations.ChangeSentAndFailureFieldType do
  use Ecto.Migration

  def change do
    alter table(:sent_messages) do
      modify :payload, :jsonb
    end

    alter table(:failed_messages) do
      modify :payload, :jsonb
    end
  end
end
