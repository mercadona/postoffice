defmodule Postoffice.MessagingTest do
  use Postoffice.DataCase

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Message
  alias Postoffice.Fixtures

  @second_topic_attrs %{
    name: "test2"
  }

  @disabled_publisher_attrs %{
    active: false,
    endpoint: "http://fake.endpoint/disabled",
    initial_message: 0,
    type: "http"
  }

  @message_attrs %{
    attributes: %{},
    payload: %{},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  @second_publisher_attrs %{
    active: true,
    endpoint: "http://fake.endpoint2",
    initial_message: 0,
    type: "http"
  }

  @invalid_message_attrs %{attributes: nil, payload: nil, public_id: nil, topic: nil}

  describe "messages" do
    test "list_messages/0 returns all messages" do
      topic = Fixtures.create_topic()
      message = Fixtures.create_message(topic)

      assert Messaging.list_messages() == [message]
    end

    test "list_messages/0 returns empty list in case no message exists" do
      assert Messaging.list_messages() == []
    end

    test "get_message!/1 returns the message with given id" do
      topic = Fixtures.create_topic()
      message = Fixtures.create_message(topic)
      message_found = Messaging.get_message!(message.id)

      assert message.id == message_found.id
    end

    test "create_message/1 with valid data creates a message" do
      topic = Fixtures.create_topic()

      assert {:ok, %Message{} = message} = Messaging.create_message(topic, @message_attrs)
      assert message.attributes == %{}
      assert message.payload == %{}
      assert message.public_id == "7488a646-e31f-11e4-aace-600308960662"
      assert message.topic_id == topic.id
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Messaging.create_message(Fixtures.create_topic(), @invalid_message_attrs)
    end

    test "list_topics/0 returns all topics" do
      topic = Fixtures.create_topic()

      assert Messaging.list_topics() == [topic]
    end

    test "list_topics/0 returns empty list in case no topic exists" do
      assert Messaging.list_topics() == []
    end

    test "list_publishers/0 returns empty list if no publisher exists" do
      assert Messaging.list_publishers() == []
    end

    test "list_publishers/0 returns all existing publishers" do
      publisher = Fixtures.create_publisher(Fixtures.create_topic())
      listed_publisher = List.first(Messaging.list_publishers())

      assert publisher.id == listed_publisher.id
      assert publisher.endpoint == listed_publisher.endpoint
      assert publisher.active == listed_publisher.active
      assert publisher.type == listed_publisher.type
    end

    test "list_enabled_publishers/0 returns only enabled publishers" do
      topic = Fixtures.create_topic()
      _ = Fixtures.create_publisher(topic, @disabled_publisher_attrs)
      enabled_publisher = Fixtures.create_publisher(topic)
      listed_publisher = List.first(Messaging.list_enabled_publishers())

      assert enabled_publisher.id == listed_publisher.id
      assert enabled_publisher.endpoint == listed_publisher.endpoint
      assert enabled_publisher.active == listed_publisher.active
      assert enabled_publisher.type == listed_publisher.type
    end

    test "get_message_by_uuid returns message is found" do
      topic = Fixtures.create_topic()
      message = Fixtures.create_message(topic)
      searched_message = Messaging.get_message_by_uuid(message.public_id)

      assert message.id == searched_message.id
    end

    test "message_already_processed returns false if it hasnt been processed for a publisher" do
      topic = Fixtures.create_topic()
      message = Fixtures.create_message(topic)
      publisher = Fixtures.create_publisher(topic)

      assert Messaging.message_already_processed(message.id, publisher.id) == false
    end

    test "message_already_processed returns true if it has been processed for a publisher" do
      topic = Fixtures.create_topic()
      message = Fixtures.create_message(topic)
      publisher = Fixtures.create_publisher(topic)
      Fixtures.create_publisher_success(message, publisher)

      assert Messaging.message_already_processed(message.id, publisher.id)
    end

    test "list_pending_messages_for_publisher/2 returns empty if no pending messages for a given publisher" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      assert Messaging.list_pending_messages_for_publisher(publisher.id, topic.id) == []
    end

    test "list_pending_messages_for_publisher/2 returns empty if no pending messages for a given publisher but we have pending messages for other publisher" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      second_topic = Fixtures.create_topic(@second_topic_attrs)
      _second_publisher = Fixtures.create_publisher(second_topic, @second_publisher_attrs)
      _message = Fixtures.create_message(second_topic)

      assert Messaging.list_pending_messages_for_publisher(publisher.id, topic.id) == []
    end

    test "list_pending_messages_for_publisher/2 returns messages for a given publisher and topic" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.create_message(topic)

      pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id, topic.id)

      assert Kernel.length(pending_messages) == 1
      pending_message = List.first(pending_messages)
      assert pending_message.id == message.id
      assert pending_message.topic_id == topic.id
    end

    test "list_pending_messages_for_publisher/2 returns messages for a given publisher and topic when there are pending messages for other topics" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.create_message(topic)

      second_topic = Fixtures.create_topic(@second_topic_attrs)
      Fixtures.create_publisher(second_topic, @second_publisher_attrs)

      _second_message =
        Fixtures.create_message(
          second_topic,
          Map.put(@message_attrs, :public_id, "2d823585-68f8-49cd-89c0-07c1572572c1")
        )

      pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id, topic.id)

      assert Kernel.length(pending_messages) == 1
      pending_message = List.first(pending_messages)
      assert pending_message.id == message.id
      assert pending_message.topic_id == topic.id
    end
  end

  describe "counters" do
    test "count_topics returns 0 if no topic exists" do
      assert Messaging.count_topics() == 0
    end

    test "count_topics returns number of created topics" do
      _topic = Fixtures.create_topic()

      assert Messaging.count_topics() == 1
    end

    test "count_messages returns 0 if no message exists" do
      assert Messaging.count_messages() == 0
    end

    test "count_messages returns number of created messages" do
      topic = Fixtures.create_topic()
      _message = Fixtures.create_message(topic)

      assert Messaging.count_messages() == 1
    end

    test "count_publishers returns 0 if no publisher exists" do
      assert Messaging.count_publishers() == 0
    end

    test "count_publishers returns number of created publishers" do
      topic = Fixtures.create_topic()
      _publisher = Fixtures.create_publisher(topic)
      _publisher = Fixtures.create_publisher(topic, @second_publisher_attrs)

      assert Messaging.count_publishers() == 2
    end

    test "count_published_messages returns 0 if no published message exists" do
      assert Messaging.count_published_messages() == 0
    end

    test "count_published_messages returns number of published messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.create_message(topic)
      Fixtures.create_publisher_success(message, publisher)

      assert Messaging.count_published_messages() == 1
    end

    test "count_publishers_failures returns 0 if no failed message exists" do
      assert Messaging.count_publishers_failures() == 0
    end

    test "count_publishers_failures returns number of failed messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.create_message(topic)
      Fixtures.create_publishers_failure(message, publisher)

      assert Messaging.count_publishers_failures() == 1
    end
  end
end
