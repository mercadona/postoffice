defmodule Postoffice.Messaging.PublisherSuccess do
  use Ecto.Schema
  import Ecto.Changeset

  schema "publisher_success" do
    belongs_to :publisher, Postoffice.Messaging.Publisher
    belongs_to :message, Postoffice.Messaging.Message
    timestamps()
  end

  @doc false
  def changeset(publisher_success, attrs) do
    publisher_success
    |> cast(attrs, [:message_id, :publisher_id])
    |> validate_required([:message_id, :publisher_id])
  end
end
