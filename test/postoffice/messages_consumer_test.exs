defmodule Postoffice.MessagesConsumerTest do
  use Postoffice.DataCase, async: true

  import Mox

  alias Postoffice
  alias Postoffice.Adapters.HttpMock
  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.MessagesConsumer

  @message_attrs %{
    attributes: %{},
    payload: %{},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  setup [:set_mox_from_context, :verify_on_exit!]

  describe "MessagesConsumer tests" do
    test "message from messaging context must be valid for this module" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      {_, message} = Messaging.add_message_to_deliver(topic, @message_attrs)

      pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)
      pending_message = List.first(pending_messages)

      expect(HttpMock, :publish, fn "http://fake.target", ^message ->
        {:ok, %HTTPoison.Response{status_code: 200}}
      end)

      MessagesConsumer.start_link(pending_message)
      Process.sleep(300)
    end
  end
end
