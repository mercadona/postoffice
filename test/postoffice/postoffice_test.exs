defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase

  alias Postoffice
  alias Postoffice.Messaging
  alias Postoffice.Fixtures, as: Fixtures

  @publisher_attrs %{
    active: true,
    endpoint: "http://fake.endpoint2",
    initial_message: 0,
    type: "http"
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
      Fixtures.create_message(topic)

      assert Postoffice.count_received_messages() == 1
    end

    test "count_published_messages returns 0 if no published message exists" do
      assert Postoffice.count_published_messages() == 0
    end

    test "count_published_messages returns number of published messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.create_message(topic)
      Fixtures.create_publisher_success(message, publisher)

      assert Postoffice.count_published_messages() == 1
    end

    test "count_publishers_failures returns 0 if no failed message exists" do
      assert Postoffice.count_publishers_failures() == 0
    end

    test "count_publishers_failures returns number of failed messages" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)
      message = Fixtures.create_message(topic)
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
  end
end
