defmodule Postoffice.Messaging.PublisherFailures do
  use Ecto.Schema
  import Ecto.Changeset

  schema "publisher_failures" do
    belongs_to :publisher, Postoffice.Messaging.Publisher
    belongs_to :message, Postoffice.Messaging.Message
    field :processed, :boolean
    timestamps()
  end

  @doc false
  def changeset(publisher_failed, attrs) do
    publisher_failed
    |> cast(attrs, [:message_id, :publisher_id])
    |> validate_required([:message_id, :publisher_id])
  end
end
