defmodule Postoffice.Messaging.Publisher do
  use Ecto.Schema
  import Ecto.Changeset
  alias Postoffice.Messaging

  schema "publishers" do
    field :active, :boolean, default: false
    field :endpoint, :string
    field :type, :string
    field :initial_message, :integer
    belongs_to :topic, Postoffice.Messaging.Topic

    has_many :publisher_success, Postoffice.Messaging.PublisherSuccess

    timestamps()
  end

  @doc false
  def changeset(consumer_http, attrs) do
    consumer_http
    |> cast(attrs, [:endpoint, :active, :type, :topic_id, :initial_message])
    |> validate_required([:endpoint, :active, :topic_id, :type, :initial_message])
    |> validate_inclusion(:type, Keyword.values(types()))
    |> validate_endpoint()
  end

  def validate_endpoint(changeset) do
    type = get_field(changeset, :type)
    endpoint = get_field(changeset, :endpoint)
    topic = get_field(changeset, :topic_id) |> Messaging.get_topic_for_id

    if type == "pubsub" and topic.name != endpoint do
      add_error(changeset, :endpoint, "is invalid")
    else
      changeset
    end
  end

  def types do
    [Http: "http", PubSub: "pubsub"]
  end
end
