defmodule Postoffice.Repo.Migrations.RenameEndpointByTargeFromPublisher do
  use Ecto.Migration

  def change do
    rename table(:publishers), :endpoint, to: :target
  end
end
