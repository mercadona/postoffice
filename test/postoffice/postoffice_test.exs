defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase, async: true

  alias Postoffice
  alias Postoffice.Fixtures

  @publisher_attrs %{
    active: true,
    target: "http://fake.target2",
    type: "http"
  }

  describe "Postoffice api" do
    test "estimated_messages_count returns 0 if no message exists" do
      assert Postoffice.estimated_messages_count() == 0
    end

    test "estimated_published_messages_count returns 0 if no published message exists" do
      assert Postoffice.estimated_published_messages_count() == 0
    end

    test "count_publishers_failures returns 0 if no failed message exists" do
      Cachex.reset!(:retry_cache)
      assert Postoffice.count_publishers_failures() == 0
    end

    test "count_publishers_failures returns number of failed messages" do
      Cachex.reset!(:retry_cache)
      publisher_id = 1
      message_id = 2
      Cachex.put(:retry_cache, {publisher_id, message_id}, 1,
        ttl: :timer.seconds(1)
      )

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
