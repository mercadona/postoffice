defmodule Postoffice.Fixtures do
  @moduledoc """
  This module defines the shared fixtures between the tests
  """
  alias Postoffice
  alias Postoffice.Messaging
  alias Postoffice.Repo

  @topic_attrs %{
    name: "test",
    origin_host: "example.com",
    recovery_enabled: true
  }

  @message_attrs %{
    attributes: %{},
    payload: %{},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  @publisher_attrs %{
    active: true,
    target: "http://fake.target",
    initial_message: 0,
    type: "http"
  }

  def add_message_to_deliver(topic, attrs \\ @message_attrs) do
    {:ok, message} = Messaging.add_message_to_deliver(topic, attrs)

    message
  end

  def create_topic(attrs \\ @topic_attrs) do
    {:ok, topic} = Messaging.create_topic(attrs)
    topic
  end

  def create_publisher(topic, attrs \\ @publisher_attrs) do
    {:ok, publisher} = Messaging.create_publisher(Map.put(attrs, :topic_id, topic.id))
    publisher
  end

  def create_publisher_success(message, publisher) do
    {:ok, _publisher_success} =
      Messaging.create_publisher_success(%{message_id: message.id, publisher_id: publisher.id})
      |> Repo.insert()
  end

  def create_publishers_failure(message, publisher) do
    {:ok, _publisher_success} =
      Messaging.create_publisher_failure(%{message_id: message.id, publisher_id: publisher.id})
  end

  def pubsub_conn(), do: %Tesla.Client{
    adapter: nil,
    fun: nil,
    post: [],
    pre: [
      {Tesla.Middleware.Headers, :call,
       [
         [
           {"authorization",
            "Bearer ya29.c.Ko8BywcJmQ044Tz44v_NoMQ03cXByM1rMjKSFKBWpjcCE2RLIDlxlWvlSXC8gSYtQTmdkRi-wA-mzFsSn37l1uV7TlbHq5rIqqdDbr746sECtpT5vF1JEskVLC2VsEBc-ukAT4C8hb-n1xXLw00S2M5kCBANtdSsbkeTG1I57fuIGN3dU3TSKtRzmZ0on5Anlgs"}
         ]
       ]}
    ]
  }
end
