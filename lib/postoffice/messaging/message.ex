defmodule Postoffice.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :attributes, :map
    field :payload, :map
    belongs_to :topic, Postoffice.Messaging.Topic

    has_many :publisher_success, Postoffice.Messaging.PublisherSuccess

    timestamps()

    field :publisher_id, :string, virtual: true
    field :publisher_type, :string, virtual: true
    field :publisher_target, :string, virtual: true
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:payload, :attributes])
    |> validate_required([:payload, :attributes])
  end
end
