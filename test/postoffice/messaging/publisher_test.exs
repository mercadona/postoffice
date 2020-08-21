defmodule Postoffice.Messaging.PublisherTest do
  use Postoffice.DataCase, async: true

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Fixtures

  @topic_attrs %{
    name: "test2",
    origin_host: "example2.com",
    recovery_enabled: false
  }

  @pubsub_publisher_attrs %{
    active: true,
    target: "http://fake.target2",
    initial_message: 0,
    type: "pubsub"
  }

  describe "publishers" do
    test "calculate_chunk_size/1 returns 1 when publisher's type is http" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      assert Publisher.calculate_chunk_size(publisher) == 1
    end

    test "calculate_chunk_size/1 returns 100 when publisher's type is pubsub and no chunk specified" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic, @pubsub_publisher_attrs)

      assert Publisher.calculate_chunk_size(publisher) == 100
    end

    test "calculate_chunk_size/1 returns publishers chunk_size when publisher's type is pubsub" do
      topic = Fixtures.create_topic()
      attrs = Map.put(@pubsub_publisher_attrs, :chunk_size, 10)

      publisher = Fixtures.create_publisher(topic, attrs)

      assert Publisher.calculate_chunk_size(publisher) == 10
    end
  end
end
