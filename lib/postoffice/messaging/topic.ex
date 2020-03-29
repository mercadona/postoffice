defmodule Postoffice.Messaging.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string, null: false
    field :origin_host, :string, null: true
    field :recovery_enabled, :boolean, null: false, default: false

    has_many :consumers, Postoffice.Messaging.Publisher
    has_many :messages, Postoffice.Messaging.Message
    has_many :pending_messages, Postoffice.Messaging.PendingMessage

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :origin_host, :recovery_enabled])
    |> validate_required([:name, :origin_host])
    |> unique_constraint(:name)
  end
end
