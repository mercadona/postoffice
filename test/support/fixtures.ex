defmodule Postoffice.Fixtures do
  @moduledoc """
  This module defines the shared fixtures between the tests
  """
  alias Postoffice
  alias Postoffice.Messaging
  alias Postoffice.Repo
  import Ecto.Changeset

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

  def create_failing_message(data) do
    {:ok, oban} =
      data
      |> Oban.Job.new(queue: :http, worker: Postoffice.SomeFakeWorker)
      |> Repo.insert()

    {:ok, updated_job} =
      Repo.get(Oban.Job, oban.id)
      |> change(%{state: "retryable"})
      |> Repo.update()

    updated_job
  end
end
