defmodule Postoffice.Messaging.Publisher do
  use Ecto.Schema
  import Ecto.Changeset

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
  end

  def types do
    [Http: "http", PubSub: "pubsub"]
  end
end
