defmodule Postoffice.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :attributes, :map
    field :payload, :map
    field :public_id, Ecto.UUID
    belongs_to :topic, Postoffice.Messaging.Topic

    has_many :publisher_success, Postoffice.Messaging.PublisherSuccess
    has_many :pending_messages, Postoffice.Messaging.PendingMessage

    timestamps()

    field :publisher_id, :string, virtual: true
    field :publisher_type, :string, virtual: true
    field :publisher_target, :string, virtual: true
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:payload, :attributes, :public_id])
    |> validate_required([:payload, :attributes, :public_id])
  end
end
