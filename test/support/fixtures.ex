defmodule Postoffice.Fixtures do
  @moduledoc """
  This module defines the shared fixtures between the tests
  """
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

  @publisher_attrs %{
    active: true,
    endpoint: "http://fake.endpoint",
    initial_message: 0,
    type: "http"
  }

  def message_fixture(topic, attrs \\ @message_attrs) do
    {:ok, message} = Messaging.create_message(topic, attrs)

    message
  end

  def topic_fixture(attrs \\ @topic_attrs) do
    {:ok, topic} = Messaging.create_topic(attrs)
    topic
  end

  def publisher_fixture(topic, attrs \\ @publisher_attrs) do
    {:ok, publisher} = Messaging.create_publisher(Map.put(attrs, :topic_id, topic.id))
    publisher
  end

  def publisher_success_fixture(message, publisher) do
    {:ok, _publisher_success} =
      Messaging.create_publisher_success(%{message_id: message.id, publisher_id: publisher.id})
  end

  def publishers_failure_fixture(message, publisher) do
    {:ok, _publisher_success} =
      Messaging.create_publisher_failure(%{message_id: message.id, publisher_id: publisher.id})
  end
end
