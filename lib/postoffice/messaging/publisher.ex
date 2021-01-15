defmodule Postoffice.Messaging.Publisher do
  use Ecto.Schema
  import Ecto.Changeset

  schema "publishers" do
    field :active, :boolean, default: false
    field :target, :string
    field :type, :string
    belongs_to :topic, Postoffice.Messaging.Topic
    field :seconds_timeout, :integer, default: 5
    field :chunk_size, :integer
    field :seconds_retry, :integer, default: 30
    field :deleted, :boolean, default: false

    timestamps()
  end

  @doc false

  def changeset(consumer_http, attrs) do
    consumer_http
    |> cast(attrs, [
      :target,
      :active,
      :type,
      :topic_id,
      :seconds_timeout,
      :seconds_retry,
      :chunk_size,
      :deleted
    ])
    |> validate_required([:target, :active, :topic_id, :type])
    |> unique_constraint(:target, name: :publishers_topic_id_target_type_index)
    |> validate_inclusion(:type, Keyword.values(types()))
  end

  def types do
    [Http: "http", PubSub: "pubsub"]
  end
end
