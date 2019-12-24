defmodule Postoffice.Messaging.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string, null: false

    has_many :consumers, Postoffice.Messaging.Publisher
    has_many :messages, Postoffice.Messaging.Message

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
