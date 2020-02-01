defmodule Postoffice.Handlers.HttpTest do
  use ExUnit.Case

  import Mox

  alias Postoffice.Adapters.HttpMock
  alias Postoffice.Handlers.Http
  alias Postoffice.Messaging

  @valid_message_attrs %{
    attributes: %{},
    payload: %{},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }
  @valid_publisher_attrs %{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "test",
    type: "http",
    initial_message: 0
  }
  @valid_topic_attrs %{
    name: "test"
  }

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  end

  test "no message_success when target endpoint not found" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.create_message(topic, @valid_message_attrs)

    expect(HttpMock, :publish, fn "http://fake.endpoint", ^message ->
      {:error, 404}
    end)

    Http.run(publisher.endpoint, publisher.id, message)
    assert [] = Messaging.list_publisher_success(publisher.id)
    message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert message_failure.message_id == message.id
  end

  test "message success is created for publisher if message is successfully delivered" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.create_message(topic, @valid_message_attrs)

    expect(HttpMock, :publish, fn "http://fake.endpoint", ^message ->
      {:ok, message}
    end)

    Http.run(publisher.endpoint, publisher.id, message)
    assert [message] = Messaging.list_publisher_success(publisher.id)
  end

  test "message_failure is created for publisher if any error happens" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.create_message(topic, @valid_message_attrs)

    expect(HttpMock, :publish, fn "http://fake.endpoint", ^message ->
      {:error, %HTTPoison.Error{reason: "test"}}
    end)

    Http.run(publisher.endpoint, publisher.id, message)
    message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert message_failure.message_id == message.id
  end

  test "message_failure is created for publisher if response is :ok but response_code != 200" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, message} = Messaging.create_message(topic, @valid_message_attrs)

    expect(HttpMock, :publish, fn "http://fake.endpoint", ^message ->
      {:error, %HTTPoison.Response{status_code: 201}}
    end)

    Http.run(publisher.endpoint, publisher.id, message)
    message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert message_failure.message_id == message.id
  end
end
