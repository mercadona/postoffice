defmodule Postoffice.Repo.Migrations.AddPublisherIndexOnPublisherSuccess do
  use Ecto.Migration

  def change do
    create index("publisher_success", [:publisher_id], name: "publisher_id")
  end
end
