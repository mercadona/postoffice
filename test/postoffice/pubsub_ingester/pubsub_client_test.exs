defmodule Postoffice.PubSubIngester.PubSubClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias Postoffice.PubSubIngester.Adapters.PubSubMock
  alias Postoffice.PubSubIngester.PubSubClient
  alias Postoffice.Fixtures

  @topic_subscription_relation %{
    topic: "test",
    sub: "fake_sub"
  }

setup do
    {:ok, pubsub_conn: Fixtures.pubsub_conn()}
end

  describe "get messages from pubsub" do
    test "get messages when has not messages to receive", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :get, fn _pubsub_conn, "fake_sub" -> Fixtures.empty_google_pubsub_messages() end)

      {:ok, messages} = PubSubClient.get(pubsub_conn, @topic_subscription_relation)

      assert messages == []
    end

    test "get error from pubsub returns the error", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :get, fn _pubsub_conn, "fake_sub" -> Fixtures.pubsub_error() end)

      error = PubSubClient.get(pubsub_conn, @topic_subscription_relation)

      assert error == Fixtures.pubsub_error()
    end

    test "get messages when has messages to receive", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :get, fn _pubsub_conn, "fake_sub" -> Fixtures.two_google_pubsub_messages() end)

      {:ok, messages} = PubSubClient.get(pubsub_conn, @topic_subscription_relation)

      assert messages == [
               %{
                 "attributes" => %{},
                 "payload" => %{"one" => "two"},
                 "topic" => "test",
                 "ackId" =>
                   "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVsRDXptXFcnUAwccHxhcm1dEwIBQlJ4W3OK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E"
               },
               %{
                 "attributes" => %{"att_one" => "one"},
                 "payload" => %{"two" => "three"},
                 "topic" => "test",
                 "ackId" =>
                   "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVoRDXptXFcnUAwccHxhcm9eEwQFRFt-XnOK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E"
               }
             ]
    end
  end

  describe "confirm messages from pubsub" do
    test "confirm messages returns google response when correct ack", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :confirm, fn _pubsub_conn, ["ackId1", "ackId2"]-> Fixtures.google_ack_message() end)

      ackIds = ["ackId1", "ackId2"]

      ack_message = PubSubClient.confirm(pubsub_conn, ackIds)

      assert ack_message == ack_message
    end
  end

  describe "get connection from pubsub" do
    test "returns google connection", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :connect, fn -> pubsub_conn end)

      google_connection = PubSubClient.connect()

      assert google_connection == pubsub_conn
    end
  end
end
