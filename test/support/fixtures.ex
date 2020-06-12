defmodule Postoffice.Fixtures do
  @moduledoc """
  This module defines the shared fixtures between the tests
  """
  alias Postoffice
  alias Postoffice.Messaging
  alias Postoffice.Messaging.PublisherSuccess
  alias Postoffice.Repo

  @topic_attrs %{
    name: "test",
    origin_host: "example.com",
    recovery_enabled: true
  }

  @message_attrs %{
    attributes: %{},
    payload: %{}
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

  @spec create_publisher_success(atom | %{id: any}, atom | %{id: any}) :: any
  def create_publisher_success(message, publisher) do
    %PublisherSuccess{}
    |> PublisherSuccess.changeset(%{publisher_id: publisher.id, message_id: message.id})
    |> Repo.insert()
  end

  def create_publishers_failure(message, publisher) do
    {:ok, _publisher_failure} =
      Messaging.create_publisher_failure(%{message_id: message.id, publisher_id: publisher.id})
  end
end
