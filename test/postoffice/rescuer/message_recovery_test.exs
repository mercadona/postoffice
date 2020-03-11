defmodule Postoffice.Rescuer.MessageRecoveryTest do
  use ExUnit.Case

  import Mox

  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.Rescuer.Adapters.HttpMock
  alias Postoffice.Rescuer.MessageRecovery

  @origin_host "http://fake_origin.host"
  @first_message_id 1
  @second_message_id 2
  @one_message_response "[{\"id\": 1, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}]"
  @two_messages_response "[{\"id\": 1, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}, {\"id\": 2, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}]"
  @wrong_topic_message "[{\"id\": 1, \"topic\": \"test2\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": {}}]"

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
      assert Messaging.list_messages() == []
    end

    test "message created if one undelivered message found" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @one_message_response}}
      end)

      expect(HttpMock, :delete, fn @origin_host, @first_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      Fixtures.create_topic()
      MessageRecovery.run(@origin_host)
      assert Kernel.length(Messaging.list_messages()) == 1
    end

    test "more than one message is created if multiple undelivered messages found" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @two_messages_response}}
      end)
      expect(HttpMock, :delete, fn @origin_host, @first_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)
      expect(HttpMock, :delete, fn @origin_host, @second_message_id ->
        {:ok, %HTTPoison.Response{status_code: 204}}
      end)

      Fixtures.create_topic()
      MessageRecovery.run(@origin_host)
      assert Kernel.length(Messaging.list_messages()) == 2
    end

    test "no message created if something fails" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @wrong_topic_message}}
      end)

      MessageRecovery.run(@origin_host)
      assert Kernel.length(Messaging.list_messages()) == 0
    end
  end
end
