defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase

  alias Postoffice
  alias Postoffice.Messaging
  alias Postoffice.Fixtures, as: Fixtures

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
  end
end
