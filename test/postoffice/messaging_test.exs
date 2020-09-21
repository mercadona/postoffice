defmodule Postoffice.MessagingTest do
  use Postoffice.DataCase, async: true
  use Oban.Testing, repo: Postoffice.Repo

  alias Postoffice.Messaging
  alias Postoffice.Fixtures

  @second_topic_attrs %{
    name: "test2",
    origin_host: "example2.com",
    recovery_enabled: false
  }

  @invalid_message_attrs %{
    "topic" => "invalid_topic",
    "attributes" => %{},
    "payload" => %{}
  }

  @valid_message_attrs %{
    "topic" => "test",
    "attributes" => %{},
    "payload" => [%{"id" => "message1"}, %{"id" => "message2"}]
  }

  @message_attrs %{
    attributes: %{},
    payload: %{}
  }

  @second_publisher_attrs %{
    active: true,
    target: "http://fake.target2",
    initial_message: 0,
    type: "http"
  }

  @pubsub_publisher_attrs %{
    active: true,
    target: "test-publisher",
    initial_message: 0,
    type: "pubsub"
  }

  describe "messages" do
    test "add_message_to_deliver/1 without publisher created for this topics doesnt create any job" do
      topic = Fixtures.create_topic()
      Messaging.add_message_to_deliver(topic, @message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 0
    end

    test "add_message_to_deliver/1 with valid data creates one job" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      Messaging.add_message_to_deliver(topic, @message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 1
    end

    test "add_messages_to_deliver/2 with 2 messages and 2 publishers creates 4 jobs" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @second_publisher_attrs)

      Messaging.add_messages_to_deliver(@valid_message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 4
    end

    test "add_messages_to_deliver/2 with invalid topic returns error" do
      assert {:error, _reason} = Messaging.add_messages_to_deliver(@invalid_message_attrs)
    end

    test "create_topic/1 with recovery_enabled" do
      topic_params = %{@second_topic_attrs | recovery_enabled: true}
      {:ok, topic} = Messaging.create_topic(topic_params)

      assert topic.recovery_enabled == true
    end

    test "add_messages_to_deliver/2 for pubsub publisher creates jobs with multiple payloads" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic, @pubsub_publisher_attrs)

      Messaging.add_messages_to_deliver(@valid_message_attrs)

      assert Kernel.length(all_enqueued(queue: :pubsub)) == 1
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

    test "get_publisher! returns asked publisher data" do
      topic = Fixtures.create_topic()
      fixture_publisher = Fixtures.create_publisher(topic)

      publisher = Messaging.get_publisher!(fixture_publisher.id)
      assert publisher.id == fixture_publisher.id
      assert publisher.target == fixture_publisher.target
      assert publisher.active == fixture_publisher.active
      assert publisher.type == fixture_publisher.type
    end

    test "get_recovery_hosts returns unique hosts" do
      Fixtures.create_topic()

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

  describe "counters" do
    test "count_topics returns 0 if no topic exists" do
      assert Messaging.count_topics() == 0
    end

    test "count_topics returns number of created topics" do
      Fixtures.create_topic()

      assert Messaging.count_topics() == 1
    end

    test "count_publishers returns 0 if no publisher exists" do
      assert Messaging.count_publishers() == 0
    end

    test "count_publishers returns number of created publishers" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @second_publisher_attrs)

      assert Messaging.count_publishers() == 2
    end

    test "get_estimate_count returns 0 when no topic exists" do
      assert Messaging.get_estimated_count("topics") == 0
    end

    test "count_failing_jobs/0 returns 0 if no retryable job exists" do
      assert Messaging.count_failing_jobs() == 0
    end
  end
end
