defmodule Postoffice.Messaging.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string, null: false
    field :origin_host, :string, null: true

    has_many :consumers, Postoffice.Messaging.Publisher
    has_many :messages, Postoffice.Messaging.Message

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:name, :origin_host])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
