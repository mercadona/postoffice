defmodule Postoffice.Messaging.PendingMessage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pending_messages" do
    belongs_to :topic, Postoffice.Messaging.Topic
    belongs_to :message, Postoffice.Messaging.Message

    timestamps()
  end

  @doc false
  def changeset(pending_message, attrs) do
    pending_message
    |> cast(attrs, [:topic_id, :message_id])
    |> validate_required([:topic_id, :message_id])
  end

end
