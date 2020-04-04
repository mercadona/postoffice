defmodule Postoffice.MessagingTest do
  use Postoffice.DataCase

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Message
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.Fixtures

  @second_topic_attrs %{
    name: "test2",
    origin_host: "example2.com",
    recovery_enabled: false
  }

  @disabled_publisher_attrs %{
    active: false,
    target: "http://fake.target/disabled",
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
    target: "http://fake.target2",
    initial_message: 0,
    type: "http"
  }

  @invalid_message_attrs %{attributes: nil, payload: nil, public_id: nil, topic: nil}

  describe "messages" do
    test "list_messages/0 returns all messages" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)

      assert Messaging.list_messages() == [message]
    end

    test "list_messages/0 returns empty list in case no message exists" do
      assert Messaging.list_messages() == []
    end

    test "list_messages/1 returns limited messages list" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)

      _second_message =
        Fixtures.add_message_to_consume(topic, %{
          @message_attrs
          | public_id: "7488a646-e31f-11e4-aace-600308960661"
        })

      assert Messaging.list_messages(1) == [message]
    end

    test "get_message!/1 returns the message with given id" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)
      message_found = Messaging.get_message!(message.id)

      assert message.id == message_found.id
    end

    test "create_message/1 with valid data creates a message" do
      topic = Fixtures.create_topic()

      assert {:ok, %Message{} = message} = Messaging.add_message_to_consume(topic, @message_attrs)
      assert message.attributes == %{}
      assert message.payload == %{}
      assert message.public_id == "7488a646-e31f-11e4-aace-600308960662"
      assert message.topic_id == topic.id
    end

    test "create_message/1 with valid data creates a pending message" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      second_publisher =
        Fixtures.create_publisher(topic, %{
          active: true,
          target: "some-topic",
          initial_message: 0,
          type: "pubsub"
        })

      {_, message} = Messaging.add_message_to_consume(topic, @message_attrs)

      assert length(Repo.all(PendingMessage)) == 2

      pending_message =
        Messaging.list_pending_messages_for_publisher(publisher.id, topic.id)
        |> List.first()
      assert pending_message.id == message.id

      pending_message =
        Messaging.list_pending_messages_for_publisher(second_publisher.id, topic.id)
        |> List.first()
      assert pending_message.id == message.id
    end

    test "create_message/1 with valid data do not create pending message if have not associated publisher" do
      topic = Fixtures.create_topic()
      second_topic = Fixtures.create_topic(@second_topic_attrs)

      Fixtures.create_publisher(
        second_topic,
        %{
          active: true,
          target: "some_target.com",
          initial_message: 0,
          type: "http"
        }
      )

      Messaging.add_message_to_consume(topic, @message_attrs)

      assert length(Repo.all(PendingMessage)) == 0
    end

    test "create_message/1 with valid data do not create pending message if do not exists any publisher" do
      topic = Fixtures.create_topic()

      Messaging.add_message_to_consume(topic, @message_attrs)

      assert length(Repo.all(PendingMessage)) == 0
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Messaging.add_message_to_consume(Fixtures.create_topic(), @invalid_message_attrs)
    end

    test "create_message/1 with invalid data do not create pending message" do
      Messaging.add_message_to_consume(Fixtures.create_topic(), @invalid_message_attrs)

      assert length(Repo.all(PendingMessage)) == 0
    end

    test "create_topic/1 with recovery_enabled" do
      topic_params = %{@second_topic_attrs | recovery_enabled: true}
      {:ok, topic} = Messaging.create_topic(topic_params)

      assert topic.recovery_enabled == true
    end

    test "create_topic/1 with disabled recovery_enabled" do
      {:ok, topic} = Messaging.create_topic(@second_topic_attrs)

      assert topic.recovery_enabled == false
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
      assert publisher.target == listed_publisher.target
      assert publisher.active == listed_publisher.active
      assert publisher.type == listed_publisher.type
    end

    test "list_enabled_publishers/0 returns only enabled publishers" do
      topic = Fixtures.create_topic()
      _ = Fixtures.create_publisher(topic, @disabled_publisher_attrs)
      enabled_publisher = Fixtures.create_publisher(topic)
      listed_publisher = List.first(Messaging.list_enabled_publishers())

      assert enabled_publisher.id == listed_publisher.id
      assert enabled_publisher.target == listed_publisher.target
      assert enabled_publisher.active == listed_publisher.active
      assert enabled_publisher.type == listed_publisher.type
    end

    test "get_message_by_uuid returns message is found" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)
      searched_message = Messaging.get_message_by_uuid(message.public_id)

      assert message.id == searched_message.id
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
      _message = Fixtures.add_message_to_consume(second_topic)

      assert Messaging.list_pending_messages_for_publisher(publisher.id, topic.id) == []
    end

    test "list_pending_messages_for_publisher/2 returns messages for a given publisher and topic" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.add_message_to_consume(topic)

      pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id, topic.id)

      assert Kernel.length(pending_messages) == 1
      pending_message = List.first(pending_messages)
      assert pending_message.id == message.id
      assert pending_message.topic_id == topic.id
    end

    test "list_pending_messages_for_publisher/2 returns messages for a given publisher and topic when there are pending messages for other topics" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.add_message_to_consume(topic)

      second_topic = Fixtures.create_topic(@second_topic_attrs)
      Fixtures.create_publisher(second_topic, @second_publisher_attrs)

      _second_message =
        Fixtures.add_message_to_consume(
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
      _message = Fixtures.add_message_to_consume(topic)

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
      message = Fixtures.add_message_to_consume(topic)
      Fixtures.create_publisher_success(message, publisher)

      assert Messaging.count_published_messages() == 1
    end

    test "count_publishers_failures returns 0 if no failed message exists" do
      assert Messaging.count_publishers_failures() == 0
    end

    test "count_publishers_failures returns number of failed messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.add_message_to_consume(topic)
      Fixtures.create_publishers_failure(message, publisher)

      assert Messaging.count_publishers_failures() == 1
    end

    test "get_publisher! returns asked publisher data" do
      topic = Fixtures.create_topic()
      fixture_publisher = Fixtures.create_publisher(topic)

      publisher = Messaging.get_publisher!(fixture_publisher.id)
      assert publisher.id == fixture_publisher.id
      assert publisher.target == fixture_publisher.target
      assert publisher.active == fixture_publisher.active
      assert publisher.type == fixture_publisher.type
    end

    test "no publisher_success is returned for a non existing message" do
      assert Messaging.get_publisher_success_for_message(1) == []
    end

    test "no publisher_success is returned for a non processed message" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)

      assert Messaging.get_publisher_success_for_message(message.id) == []
    end

    test "publisher_success for a processed messaged is returned" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)
      publisher = Fixtures.create_publisher(topic)
      _publisher_success = Fixtures.create_publisher_success(message, publisher)

      loaded_publisher_success = Messaging.get_publisher_success_for_message(message.id)
      assert Kernel.length(loaded_publisher_success) == 1
    end

    test "no publisher_failures is returned for a non existing message" do
      assert Messaging.get_publisher_failures_for_message(1) == []
    end

    test "no publisher_failures is returned for a non processed message" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)

      assert Messaging.get_publisher_failures_for_message(message.id) == []
    end

    test "publisher_failures for a processed messaged is returned" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_consume(topic)
      publisher = Fixtures.create_publisher(topic)
      _publisher_failures = Fixtures.create_publishers_failure(message, publisher)

      loaded_publisher_failures = Messaging.get_publisher_failures_for_message(message.id)
      assert Kernel.length(loaded_publisher_failures) == 1
    end

    test "get_recovery_hosts returns unique hosts" do
      _topic = Fixtures.create_topic()

      _second_topic =
        Fixtures.create_topic(%{
          name: "second_test",
          origin_host: "example.com"
        })

      hosts = Messaging.get_recovery_hosts()

      assert Kernel.length(hosts) == 1
    end

    test "get_recovery_hosts returns empty list if no topic has recovery enabled" do
      Messaging.create_topic(@second_topic_attrs)

      hosts = Messaging.get_recovery_hosts()

      assert hosts == []
    end
  end
end
