defmodule Postoffice.Workers.HttpTest do
  use ExUnit.Case, async: true

  import Mox

  alias Postoffice.Adapters.HttpMock
  alias Postoffice.Handlers.Http
  alias Postoffice.Messaging
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.Repo
  alias Postoffice.Fixtures

  @valid_message_attrs %{
    attributes: %{},
    payload: %{}
  }

  @valid_publisher_attrs %{
    active: true,
    target: "http://fake.target",
    topic: "test",
    type: "http",
    initial_message: 0,
    seconds_retry: 300
  }

  @valid_topic_attrs %{
    name: "test",
    origin_host: "example.com"
  }

  @another_valid_message_attrs %{
    attributes: %{},
    payload: %{}
  }

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  end

  test "no message_success when target not found" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 404}}
    end)

    Http.run(publisher, pending_message)
    assert [] = Messaging.list_publisher_success(publisher.id)
    message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert message_failure.message_id == message.id

    assert message_failure.reason ==
             "Error trying to process message from HttpConsumer with status_code: 404"
  end

  test "message success is created for publisher if message is successfully delivered" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 201}}
    end)

    Http.run(publisher, pending_message)
    assert [message] = Messaging.list_publisher_success(publisher.id)
  end

  test "message is removed from pending messages when is successfully delivered" do
    topic = Fixtures.create_topic(@valid_topic_attrs)
    publisher = Fixtures.create_publisher(topic)
    _message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)

    assert length(Repo.all(PendingMessage)) == 1

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 201}}
    end)

    Http.run(publisher, pending_message)
    assert length(Repo.all(PendingMessage)) == 0
  end

  test "remove only published messages from publisher" do
    topic = Fixtures.create_topic()
    publisher = Fixtures.create_publisher(topic)
    _message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)
    another_message = Fixtures.add_message_to_deliver(topic, @another_valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    assert length(Repo.all(PendingMessage)) == 2

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 201}}
    end)

    Http.run(publisher, pending_message)

    pending_messages = Messaging.list_pending_messages_for_publisher(publisher.id)
    assert Kernel.length(pending_messages) == 1
    pending_message = List.first(pending_messages)
    assert pending_message.message.id == another_message.id
  end

  test "remove only published messages for topic" do
    topic = Fixtures.create_topic()

    second_topic =
      Fixtures.create_topic(%{
        name: "test2",
        origin_host: "example2.com",
        recovery_enabled: false
      })

    publisher = Fixtures.create_publisher(topic)

    second_publisher =
      Fixtures.create_publisher(second_topic, %{
        active: true,
        target: "http://fake.target2",
        initial_message: 0,
        type: "http"
      })

    _message = Fixtures.add_message_to_deliver(topic, @valid_message_attrs)
    another_message = Fixtures.add_message_to_deliver(second_topic, @another_valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    assert length(Repo.all(PendingMessage)) == 2

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 201}}
    end)

    Http.run(publisher, pending_message)
    assert length(Repo.all(PendingMessage)) == 1

    pending_message =
      Messaging.list_pending_messages_for_publisher(second_publisher.id)
      |> List.first()

    assert pending_message.message.id == another_message.id
  end

  test "message_failure is created for publisher if any error happens" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:error, %HTTPoison.Error{reason: "test error reason"}}
    end)

    Http.run(publisher, pending_message)
    message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert message_failure.message_id == message.id

    assert message_failure.reason ==
             "Error trying to process message from HttpConsumer: test error reason"
  end

  test "do not remove pending message when can't deliver message" do
    topic = Fixtures.create_topic(@valid_topic_attrs)
    publisher = Fixtures.create_publisher(topic, @valid_publisher_attrs)

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:error, %HTTPoison.Error{reason: "test error reason"}}
    end)

    Http.run(publisher, pending_message)
    assert length(Repo.all(PendingMessage)) == 1
  end

  test "message_failure is created for publisher if response is :ok but response_code out of 200 range" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 300}}
    end)

    Http.run(publisher, pending_message)
    message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    assert message_failure.message_id == message.id

    assert message_failure.reason ==
             "Error trying to process message from HttpConsumer with status_code: 300"
  end

  test "pending_message is cached for publisher if response is :ok but response_code out of 200 range" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:ok, %HTTPoison.Response{status_code: 300}}
    end)

    Http.run(publisher, pending_message)
    :timer.sleep(100)
    {:ok, keys} = Cachex.keys(:retry_cache)
    assert {publisher.id, pending_message.id} in keys
  end

  test "pending_message is cached for publisher if any error happens" do
    {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

    {:ok, publisher} =
      Messaging.create_publisher(Map.put(@valid_publisher_attrs, :topic_id, topic.id))

    {:ok, _message} = Messaging.add_message_to_deliver(topic, @valid_message_attrs)

    pending_message =
      Messaging.list_pending_messages_for_publisher(
        publisher.id,
        1
      )
      |> hd

    message = pending_message.message

    expect(HttpMock, :publish, fn ^publisher, ^message ->
      {:error, %HTTPoison.Error{reason: "test error reason"}}
    end)

    Http.run(publisher, pending_message)
    _message_failure = List.first(Messaging.list_publisher_failures(publisher.id))
    :timer.sleep(100)
    {:ok, keys} = Cachex.keys(:retry_cache)
    assert {publisher.id, pending_message.id} in keys
  end
end
