defmodule Postoffice.MessagesConsumerTest do
  use Postoffice.DataCase, async: true

  import Mox

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice
  alias Postoffice.Adapters.HttpMock
  alias Postoffice.Adapters.PubsubMock
  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.MessagesConsumer

  @message_attrs %{
    attributes: %{},
    payload: %{}
  }

  @pubsub_publisher_attrs %{
    active: true,
    target: "http://fake.target",
    type: "pubsub"
  }

  setup [:set_mox_from_context, :verify_on_exit!]

  describe "MessagesConsumer tests" do
    test "pending message from messaging context must be valid for http module" do
      topic = Fixtures.create_topic()
      existing_publisher = Fixtures.create_publisher(topic)
      {_, message} = Messaging.add_message_to_deliver(topic, @message_attrs)

      pending_message = Messaging.list_pending_messages_for_publisher(existing_publisher.id) |> hd

      expect(HttpMock, :publish, fn ^existing_publisher, ^message ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      MessagesConsumer.start_link(%{
        publisher: existing_publisher,
        pending_message: pending_message
      })

      Process.sleep(300)
    end

    test "pending message from messaging context must be valid for pubsub module" do
      topic = Fixtures.create_topic()
      existing_publisher = Fixtures.create_publisher(topic, @pubsub_publisher_attrs)
      {_, message} = Messaging.add_message_to_deliver(topic, @message_attrs)

      pending_messages = Messaging.list_pending_messages_for_publisher(existing_publisher.id)

      expect(PubsubMock, :publish, fn ^existing_publisher, [^message] ->
        {:ok, %PublishResponse{}}
      end)

      MessagesConsumer.start_link(%{
        publisher: existing_publisher,
        pending_message: pending_messages
      })

      Process.sleep(300)
    end
  end
end
