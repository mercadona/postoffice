defmodule Postoffice.Repo.Migrations.AddSomeIndexes do
  use Ecto.Migration

  def change do
    create index("messages", [:topic_id], name: "external_topic_id")

    create index("publisher_success", [:message_id, :publisher_id],
             name: "message_and_publishers_search"
           )
  end
end
