defmodule Postoffice.Handlers.PubsubTest do
  use ExUnit.Case

  import Mox

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Adapters.PubsubMock
  alias Postoffice.Handlers.Pubsub
  alias Postoffice.Messaging
  alias Postoffice.Messaging.Message

  @valid_message_attrs %{
    attributes: %{"attr" => "some_value"},
    payload: %{"key" => "value"},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }
  @valid_publisher_attrs %{
    active: true,
    topic: "test-publisher",
    target: "test-publisher",
    type: "pubsub",
    initial_message: 0
  }
  @valid_topic_attrs %{
    name: "test-publisher"
  }
  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  end

  test "no message_success when some error raised from pubsub" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    message = %Message{
      attributes: %{},
      payload: %{},
      public_id: "7488a646-e31f-11e4-aace-600308960662",
      topic_id: topic.id
    }

    expect(PubsubMock, :publish, fn "test-publisher", ^message ->
      {:error, "test error"}
    end)

    Pubsub.run(publisher.target, publisher.id, message)
    assert [] = Messaging.list_publisher_success(publisher.id)
  end

  test "message success is created for publisher if message is successfully delivered" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.create_message(topic, @valid_message_attrs)

    expect(PubsubMock, :publish, fn "test-publisher", ^message ->
      {:ok, %PublishResponse{}}
    end)

    Pubsub.run(publisher.target, publisher.id, message)
    assert [message] = Messaging.list_publisher_success(publisher.id)
  end

  test "message failure is created for publisher if we're not able to send to pubsub" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.create_message(topic, @valid_message_attrs)

    expect(PubsubMock, :publish, fn "test-publisher", ^message ->
      {:error, "Not able to deliver"}
    end)

    Pubsub.run(publisher.target, publisher.id, message)
    publisher_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert publisher_failure.message_id == message.id
  end
end
