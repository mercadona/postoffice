defmodule Postoffice.MessagingTest do
  use Postoffice.DataCase, async: true
  use Oban.Testing, repo: Postoffice.Repo

  alias Postoffice.Messaging
  alias Postoffice.Messaging.MessageSearchParams
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

  @future_message_attrs %{
    "attributes" => %{"attribute_key" => "test"},
    "payload" => %{"value" => "test"},
    "schedule_at" => "2100-09-22T08:18:23.387Z",
    "topic" => "test"
  }

  @second_publisher_attrs %{
    active: true,
    target: "http://fake.target2",
    initial_message: 0,
    type: "http"
  }

  @deleted_publisher_attrs %{
    active: true,
    target: "http://fake.target3",
    initial_message: 0,
    type: "http",
    deleted: true
  }

  @pubsub_publisher_attrs %{
    active: true,
    target: "test-publisher",
    initial_message: 0,
    type: "pubsub"
  }

  describe "messages" do
    test "add_message_to_deliver/1 without publisher created for this topics doesn't create any job" do
      topic = Fixtures.create_topic()
      Messaging.add_message_to_deliver(topic, @message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 0
    end

    test "add_message_to_deliver/1 with valid data creates one job for no deleted publishers" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @deleted_publisher_attrs)

      Messaging.add_message_to_deliver(topic, @message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 1
    end

    test "add_messages_to_deliver/2 add messages only for no deleted publishers" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @second_publisher_attrs)
      Fixtures.create_publisher(topic, @deleted_publisher_attrs)

      Messaging.add_messages_to_deliver(@valid_message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 4
    end

    test "schedule_message set the correct _at" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      Messaging.schedule_message(@future_message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 1
      job = Oban.Job |> Repo.one()
      assert job.state == "scheduled"
      assert job.scheduled_at == ~U[2100-09-22 08:18:23.387000Z]
    end

    test "schedule_message only for no delete publishers" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @deleted_publisher_attrs)

      Messaging.schedule_message(@future_message_attrs)

      assert Kernel.length(all_enqueued(queue: :http)) == 1
      job = Oban.Job |> Repo.one()
      assert job.state == "scheduled"
      assert job.scheduled_at == ~U[2100-09-22 08:18:23.387000Z]
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

    test "list_no_deleted_publishers/0 returns empty list if no publisher exists" do
      assert Messaging.list_no_deleted_publishers() == []
    end

    test "list_no_deleted_publishers/0 returns all existing no deleted publishers" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      Fixtures.create_publisher(topic, @deleted_publisher_attrs)

      publishers = Messaging.list_no_deleted_publishers()
      assert length(publishers) == 1

      listed_publisher = List.first(publishers)

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

    test "get_failing_message!/1 returns message" do
      job = Fixtures.create_failing_message(%{id: 1, user_id: 2})
      assert Messaging.get_failing_message!(job.id) == job
    end

    test "get_failing_message!/1 returns nil" do
      assert Messaging.get_failing_message!(1) == nil
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

    test "count_failing_jobs/0 returns failing job existents" do
      Fixtures.create_failing_message(%{id: 1, user_id: 2})
      Fixtures.create_failing_message(%{id: 2, user_id: 3})

      assert Messaging.count_failing_jobs() == 2
    end

    test "count_failing_jobs/0 no returns retryable jobs when no exists" do
      failing_messages = %MessageSearchParams{topic: "", page: 1, page_size: 4}
      |> Messaging.get_failing_messages

      assert failing_messages == %{entries: [], page_number: 1, page_size: 4, total_entries: 0, total_pages: 1}
    end

    test "get_failing_messages/1 returns retryable jobs" do
      first_failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})
      second_failing_job = Fixtures.create_failing_message(%{id: 2, user_id: 3})

      failing_messages = %MessageSearchParams{topic: "", page: 1, page_size: 4}
      |> Messaging.get_failing_messages

      assert failing_messages ==  %{entries: [first_failing_job, second_failing_job], page_number: 1, page_size: 4, total_entries: 2, total_pages: 1}
    end

    test "get_failing_messages/1 returns retryable jobs paginating" do
      first_failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})
      second_failing_job = Fixtures.create_failing_message(%{id: 2, user_id: 3})

      failing_messages = %MessageSearchParams{topic: "", page: 1, page_size: 1}
      |> Messaging.get_failing_messages
      assert failing_messages ==  %{entries: [first_failing_job], page_number: 1, page_size: 1, total_entries: 2, total_pages: 2}

      failing_messages = %MessageSearchParams{topic: "", page: 2, page_size: 1}
      |> Messaging.get_failing_messages
      assert failing_messages ==  %{entries: [second_failing_job], page_number: 2, page_size: 1, total_entries: 2, total_pages: 2}
    end

    test "get_failing_messages/1 returns retryable jobs filtering by topic" do
      first_failing_job = Fixtures.create_failing_message(%{topic: "some-topic", user_id: 2})
      second_failing_job = Fixtures.create_failing_message(%{topic: "another-topic", user_id: 3})
      third_failing_job = Fixtures.create_failing_message(%{topic: "another-topic", user_id: 4})

      failing_messages = %MessageSearchParams{topic: "another-topic", page: 1, page_size: 4}
      |> Messaging.get_failing_messages

      assert failing_messages ==  %{entries: [second_failing_job, third_failing_job], page_number: 1, page_size: 4, total_entries: 2, total_pages: 1}
    end

    test "delete_failing_message/1 return :ok" do
      job = Fixtures.create_failing_message(%{id: 1, user_id: 2})
      assert Messaging.delete_failing_message(job.id) == {:ok}
    end

    test "delete_failing_message/1 return :error when failing_messages does not exist" do
      assert Messaging.delete_failing_message(1) == {:deleting_error}
    end

    test "delete_failing_message/1 count 0 retrivel jobs" do
      job1 = Fixtures.create_failing_message(%{id: 1, user_id: 2})
      job2 = Fixtures.create_failing_message(%{id: 2, user_id: 3})

      assert Messaging.count_failing_jobs() == 2

      Messaging.delete_failing_message(job1.id)
      Messaging.delete_failing_message(job2.id)

      assert Messaging.count_failing_jobs() == 0
    end
  end
end
