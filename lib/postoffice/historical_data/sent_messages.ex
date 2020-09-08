defmodule Postoffice.HistoricalData.SentMessages do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sent_messages" do
    field :message_id, :integer
    field :consumer_id, :integer
    field :payload, :map
    field :attributes, :map

    timestamps()
  end

  @doc false
  def changeset(sent_messages, attrs) do
    sent_messages
    |> cast(attrs, [:consumer_id, :message_id, :payload, :attributes])
    |> validate_required([:consumer_id, :message_id, :payload, :attributes])
  end
end
