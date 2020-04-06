defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase, async: true

  alias Postoffice
  alias Postoffice.Fixtures

  @publisher_attrs %{
    active: true,
    target: "http://fake.target2",
    initial_message: 0,
    type: "http"
  }

  @external_publisher_attrs %{
    "active" => false,
    "target" => "http://fake.target2",
    "type" => "pubsub"
  }

  describe "PostofficeWeb external api" do
    test "Returns nil if tried to find message by invalid UUID" do
      assert Postoffice.find_message_by_uuid(123) == nil
    end

    test "count_received_messages returns 0 if no message exists" do
      assert Postoffice.count_received_messages() == 0
    end

    test "count_messages returns number of created messages" do
      topic = Fixtures.create_topic()
      Fixtures.add_message_to_deliver(topic)

      assert Postoffice.count_received_messages() == 1
    end

    test "count_published_messages returns 0 if no published message exists" do
      assert Postoffice.count_published_messages() == 0
    end

    test "count_published_messages returns number of published messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.add_message_to_deliver(topic)
      Fixtures.create_publisher_success(message, publisher)

      assert Postoffice.count_published_messages() == 1
    end

    test "count_publishers_failures returns 0 if no failed message exists" do
      assert Postoffice.count_publishers_failures() == 0
    end

    test "count_publishers_failures returns number of failed messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.add_message_to_deliver(topic)
      Fixtures.create_publishers_failure(message, publisher)

      assert Postoffice.count_publishers_failures() == 1
    end

    test "count_publishers returns 0 if no publisher exists" do
      assert Postoffice.count_publishers() == 0
    end

    test "count_publishers returns number of created publishers" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @publisher_attrs)

      assert Postoffice.count_publishers() == 2
    end

    test "count_topics returns 0 if no topic exists" do
      assert Postoffice.count_topics() == 0
    end

    test "count_topics returns number of created topics" do
      Fixtures.create_topic()

      assert Postoffice.count_topics() == 1
    end

    test "ping postoffice application" do
      assert Postoffice.ping() == :ok
    end

    test "create_publisher to consume messages from_now" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_deliver(topic)
      external_publisher_attrs = Map.put(@external_publisher_attrs, "topic_id", topic.id)
      external_publisher_attrs = Map.put(external_publisher_attrs, "from_now", "true")

      {:ok, saved_publisher} = Postoffice.create_publisher(external_publisher_attrs)
      assert saved_publisher.initial_message == message.id
    end

    test "create_publisher to consume messages from first message" do
      topic = Fixtures.create_topic()
      external_publisher_attrs = Map.put(@external_publisher_attrs, "topic_id", topic.id)

      {:ok, saved_publisher} = Postoffice.create_publisher(external_publisher_attrs)
      assert saved_publisher.initial_message == 0
    end

    test "get_message by id returns asked message" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_deliver(topic)

      assert Postoffice.get_message(message.id).id == message.id
    end

    test "get_message_success returns list with success for this message" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_deliver(topic)
      publisher = Fixtures.create_publisher(topic)
      Fixtures.create_publisher_success(message, publisher)

      retrieved_success = Postoffice.get_message_success(message.id)

      assert Kernel.length(retrieved_success) == 1
    end

    test "get_message_failures returns list with failures for this message" do
      topic = Fixtures.create_topic()
      message = Fixtures.add_message_to_deliver(topic)
      publisher = Fixtures.create_publisher(topic)
      Fixtures.create_publishers_failure(message, publisher)

      retrieved_failures = Postoffice.get_message_failures(message.id)

      assert Kernel.length(retrieved_failures) == 1
    end
  end
end
