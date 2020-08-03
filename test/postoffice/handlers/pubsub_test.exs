defmodule Postoffice.Handlers.PubsubTest do
  use ExUnit.Case, async: true

  import Mox

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Adapters.PubsubMock
  alias Postoffice.Fixtures
  alias Postoffice.Handlers.Pubsub
  alias Postoffice.Messaging
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.Repo

  @valid_message_attrs %{
    attributes: %{"attr" => "some_value"},
    payload: %{"key" => "value"}
  }
  @another_valid_message_attrs %{
    attributes: %{"attr" => "some_value"},
    payload: %{"key" => "value"}
  }
  @valid_publisher_attrs %{
    active: true,
    topic: "test-publisher",
    target: "test-publisher",
    type: "pubsub",
    initial_message: 0
  }
  @valid_topic_attrs %{
    name: "test-publisher",
    origin_host: "example.com"
  }

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  end

  test "no message_success when some error raised from pubsub" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {_, message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:error, "test error"}
    end)

    Pubsub.run(publisher, pending_messages)
    assert [] = Messaging.list_publisher_success(publisher.id)
  end

  test "message success is created for publisher if message is successfully delivered" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:ok, %PublishResponse{}}
    end)

    Pubsub.run(publisher, pending_messages)
    assert [message] = Messaging.list_publisher_success(publisher.id)
  end

  test "multiple message success are created for publisher if messages are successfully delivered" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message1} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    {:ok, message2} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message2, ^message1] ->
      {:ok, %PublishResponse{}}
    end)

    Pubsub.run(publisher, pending_messages)
    assert Kernel.length(Messaging.list_publisher_success(publisher.id)) == 2
  end

  test "message failure is created for publisher if we're not able to send to pubsub" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:error, "Not able to deliver"}
    end)

    Pubsub.run(publisher, pending_messages)
    publisher_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert publisher_failure.message_id == message.id

    assert publisher_failure.reason ==
             "Error trying to process message from PubsubConsumer: Not able to deliver"
  end

  test "multiple message failures are created for publisher if we're not able to send to pubsub" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message1} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    {:ok, message2} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message2, ^message1] ->
      {:error, "Not able to deliver"}
    end)

    Pubsub.run(publisher, pending_messages)
    assert Kernel.length(Messaging.list_publisher_failures(publisher.id)) == 2
  end

  test "message is removed from pending messages when is successfully delivered" do
    topic = Fixtures.create_topic(@valid_topic_attrs)
    publisher = Fixtures.create_publisher(topic, @valid_publisher_attrs)
    message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    assert length(Repo.all(PendingMessage)) == 1

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:ok, %PublishResponse{}}
    end)

    Pubsub.run(publisher, pending_messages)
    assert length(Repo.all(PendingMessage)) == 0
  end

  test "remove only published messages for topic" do
    topic = Fixtures.create_topic()

    second_topic =
      Fixtures.create_topic(%{
        name: "test2",
        origin_host: "example2.com",
        recovery_enabled: false
      })

    publisher = Fixtures.create_publisher(topic, @valid_publisher_attrs)
    second_publisher = Fixtures.create_publisher(second_topic, @valid_publisher_attrs)
    message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)
    another_message = Fixtures.add_message_to_deliver(second_topic, @another_valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    assert length(Repo.all(PendingMessage)) == 2

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:ok, %PublishResponse{}}
    end)

    Pubsub.run(publisher, pending_messages)
    assert length(Repo.all(PendingMessage)) == 1

    pending_message =
      Messaging.list_pending_messages_for_publisher(second_publisher.id)
      |> List.first()

    assert pending_message.message.id == another_message.id
  end

  test "remove only published messages from topic" do
    topic = Fixtures.create_topic()
    publisher = Fixtures.create_publisher(topic, @valid_publisher_attrs)
    message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)
    _another_message = Fixtures.add_message_to_deliver(topic, @another_valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id, 1)

    assert length(Repo.all(PendingMessage)) == 2

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:ok, %PublishResponse{}}
    end)

    Pubsub.run(publisher, pending_messages)
    assert length(Repo.all(PendingMessage)) == 1

    expected_pending_message = Messaging.list_pending_messages_for_publisher(publisher.id)

    assert Kernel.length(expected_pending_message) == 1
  end

  test "do not remove pending message when can't deliver message" do
    topic = Fixtures.create_topic(@valid_topic_attrs)
    publisher = Fixtures.create_publisher(topic, @valid_publisher_attrs)
    message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message] ->
      {:error, "Not able to deliver"}
    end)

    Pubsub.run(publisher, pending_messages)
    assert length(Repo.all(PendingMessage)) == 1
  end

  test "pending message keys are cached in case of failure to delay retries" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    {:ok, message2} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)
    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)

    expect(PubsubMock, :publish, fn ^publisher, [^message2, ^message] ->
      {:error, "Not able to deliver"}
    end)

    Pubsub.run(publisher, pending_messages)
    {:ok, keys} = Cachex.keys(:retry_cache)

    Enum.each(pending_messages, fn pending_message ->
      assert {publisher.id, pending_message.id} in keys
    end)
  end
end
