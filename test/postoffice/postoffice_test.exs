defmodule Postoffice.PostofficeTest do
  use Postoffice.DataCase

  alias Postoffice
  alias Postoffice.Messaging

  @topic_attrs %{
    name: "test"
  }

  @message_attrs %{
    attributes: %{},
    payload: %{},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  def message_fixture(topic, attrs \\ @message_attrs) do
    {:ok, message} = Messaging.create_message(topic, attrs)

    message
  end

  def topic_fixture(attrs \\ @topic_attrs) do
    {:ok, topic} = Messaging.create_topic(attrs)
    topic
  end

  describe "PostofficeWeb external api" do
    test "Returns nil if tried to find message by invalid UUID" do
      assert Postoffice.find_message_by_uuid(123) == nil
    end

    test "count_received_messages returns 0 if no message exists" do
      assert Postoffice.count_received_messages() == 0
    end

    test "count_messages returns number of created messages" do
      topic = topic_fixture()
      message_fixture(topic)

      assert Postoffice.count_received_messages() == 1
    end
  end
end
