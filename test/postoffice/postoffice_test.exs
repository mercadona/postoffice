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
      topic = Fixtures.topic_fixture()
      Fixtures.message_fixture(topic)

      assert Postoffice.count_received_messages() == 1
    end

    test "count_published_messages returns 0 if no published message exists" do
      assert Postoffice.count_published_messages() == 0
    end

    test "count_published_messages returns number of published messages" do
      topic = Fixtures.topic_fixture()
      publisher = Fixtures.publisher_fixture(topic)
      message = Fixtures.message_fixture(topic)
      Fixtures.publisher_success_fixture(message, publisher)

      assert Postoffice.count_published_messages() == 1
    end

    test "count_publishers_failures returns 0 if no failed message exists" do
      assert Postoffice.count_publishers_failures() == 0
    end

    test "count_publishers_failures returns number of failed messages" do
      topic = Fixtures.topic_fixture()
      publisher = Fixtures.publisher_fixture(topic)
      message = Fixtures.message_fixture(topic)
      Fixtures.publishers_failure_fixture(message, publisher)

      assert Postoffice.count_publishers_failures() == 1
    end

    test "count_publishers returns 0 if no publisher exists" do
      assert Postoffice.count_publishers() == 0
    end

    test "count_publishers returns number of created publishers" do
      topic = Fixtures.topic_fixture()
      Fixtures.publisher_fixture(topic)
      Fixtures.publisher_fixture(topic, @publisher_attrs)

      assert Postoffice.count_publishers() == 2
    end
  end
end
