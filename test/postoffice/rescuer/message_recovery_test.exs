defmodule Postoffice.Rescuer.MessageRecoveryTest do
  use ExUnit.Case, async: true
  use Oban.Testing, repo: Postoffice.Repo

  import Mox

  alias Postoffice.Fixtures
  alias Postoffice.Rescuer.Adapters.HttpMock
  alias Postoffice.Rescuer.MessageRecovery

  @origin_host "http://fake_origin.host"
  @first_message_id 1
  @second_message_id 2
  @one_message_response "[{\"id\": 1, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}]"
  @two_messages_response "[{\"id\": 1, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}, {\"id\": 2, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}]"
  @wrong_topic_message "[{\"id\": 1, \"topic\": \"test2\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}]"
  @bulk_message_response "[{\"id\": 1, \"topic\": \"test\", \"bulk\": true, \"payload\": [{\"topic\": \"test\", \"payload\": {\"product\": 1234}, \"attributes\": {}}, {\"topic\": \"test\", \"payload\": {\"product\": 1234}, \"attributes\": {}}]}]"

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  end

  describe "recover messages" do
    test "no message created if no undelivered message found" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "[]"}}
      end)

      MessageRecovery.run(@origin_host)
      assert all_enqueued(queue: :http) == []
    end

    test "message created if one undelivered message found" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @one_message_response}}
      end)

      expect(HttpMock, :delete, fn @origin_host, @first_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      MessageRecovery.run(@origin_host)
      assert Kernel.length(all_enqueued(queue: :http)) == 1
    end

    test "messages created if more than one undelivered message found" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @two_messages_response}}
      end)

      expect(HttpMock, :delete, fn @origin_host, @first_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      expect(HttpMock, :delete, fn @origin_host, @second_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      MessageRecovery.run(@origin_host)
      assert Kernel.length(all_enqueued(queue: :http)) == 2
    end

    test "messages created if response is from bulk failure" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @bulk_message_response}}
      end)

      expect(HttpMock, :delete, fn @origin_host, @first_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      MessageRecovery.run(@origin_host)
      assert Kernel.length(all_enqueued(queue: :http)) == 2
    end

    test "no message created if something fails" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @wrong_topic_message}}
      end)

      MessageRecovery.run(@origin_host)
      assert Kernel.length(all_enqueued(queue: :http)) == 0
    end

    test "no message created as pending if something fails" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @wrong_topic_message}}
      end)

      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)
      MessageRecovery.run(@origin_host)

      assert Kernel.length(all_enqueued(queue: :http)) == 0
    end
  end
end
