defmodule Postoffice.HistoricalData.FailedMessages do
  use Ecto.Schema
  import Ecto.Changeset

  schema "failed_messages" do
    field :attributes, :map
    field :consumer_id, :integer
    field :message_id, :integer
    field :payload, {:array, :map}
    field :reason, :string

    timestamps()
  end

  @doc false
  def changeset(failed_messages, attrs) do
    failed_messages
    |> cast(attrs, [:consumer_id, :message_id, :payload, :attributes, :reason])
    |> validate_required([:consumer_id, :message_id, :payload, :attributes, :reason])
  end
end
