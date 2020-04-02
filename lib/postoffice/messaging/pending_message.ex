defmodule Postoffice.Messaging.PendingMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pending_messages" do
    belongs_to :message, Postoffice.Messaging.Message
    belongs_to :publisher, Postoffice.Messaging.Publisher

    timestamps()
  end

  @doc false
  def changeset(pending_message, attrs) do
    pending_message
    |> cast(attrs, [:publisher_id, :message_id])
    |> validate_required([:publisher_id, :message_id])
  end
end
