defmodule Postoffice.Rescuer.ClientTest do
  use ExUnit.Case

  import Mox

  alias Postoffice.Rescuer.Adapters.HttpMock
  alias Postoffice.Rescuer.Client

  @origin_host "http://fake_origin.host"
  @one_message_response "[{\"id\": 1, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": null}]"
  @two_messages_response "[{\"id\": 1, \"topic\": \"test\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": null}, {\"id\": 2, \"topic\": \"test2\", \"payload\": {\"products\": [{\"code\": \"1234\"}, {\"code\": 2345}], \"reference\": 1234}, \"attributes\": null}]"

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Postoffice.Repo)
  end

  describe "list undelivered messages" do
    test "non successful response from origin host" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 300}}
      end)

      {:error, pending_messages} = Client.list(@origin_host)
      assert pending_messages == []
    end

    test "origin host returns an error" do
      expect(HttpMock, :list, fn @origin_host ->
        {:error, %HTTPoison.Error{reason: "test error"}}
      end)

      {:error, pending_messages} = Client.list(@origin_host)
      assert pending_messages == []
    end

    test "no pending messages returned" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "[]"}}
      end)

      {:ok, pending_messages} = Client.list(@origin_host)
      assert pending_messages == []
    end

    test "one pending message received" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @one_message_response}}
      end)

      {:ok, pending_messages} = Client.list(@origin_host)
      assert Kernel.length(pending_messages) == 1
    end

    test "two pending messages received" do
      expect(HttpMock, :list, fn @origin_host ->
        {:ok, %HTTPoison.Response{status_code: 200, body: @two_messages_response}}
      end)

      {:ok, pending_messages} = Client.list(@origin_host)
      assert Kernel.length(pending_messages) == 2
    end
  end
end

# ""
