defmodule Postoffice.PubSubIngester.PubSubClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias Postoffice.PubSubIngester.Adapters.PubSubMock
  alias Postoffice.PubSubIngester.PubSubClient
  alias Postoffice.Fixtures

  @without_messages {:ok, %GoogleApi.PubSub.V1.Model.PullResponse{receivedMessages: nil}}

  @pubsub_error {:error,
                 %Tesla.Env{
                   __client__: %Tesla.Client{
                     adapter: nil,
                     fun: nil,
                     post: [],
                     pre: [
                       {Tesla.Middleware.Headers, :call,
                        [
                          [
                            {"authorization",
                             "Bearer ya29.c.Ko8BywcP1ge4PXhiA4y9_qgO7P1qDmSwntuVMz0eMZUJKUH5eIezGJ0ZTNqEFFz4jMHwoKH9gFKvwaA9f6ty3hD6wkciYkfvbS74ebxr8usYuMmTi3ZOzGkyv4meYnj5yu37wtbsPtyOCSZSgT4BL9QtbG5_f1T9fFtqklhGkTROfU1F7UZYkXny47fXO53up8c"}
                          ]
                        ]}
                     ]
                   },
                   __module__: GoogleApi.PubSub.V1.Connection,
                   body:
                     "{\n  \"error\": {\n    \"code\": 404,\n    \"message\": \"Resource not found (resource=supply-test-juan).\",\n    \"status\": \"NOT_FOUND\"\n  }\n}\n",
                   headers: [
                     {"cache-control", "private"},
                     {"date", "Sun, 17 May 2020 19:19:38 GMT"},
                     {"accept-ranges", "none"},
                     {"server", "ESF"},
                     {"vary", "X-Origin"},
                     {"content-length", "130"},
                     {"content-type", "application/json; charset=UTF-8"},
                     {"x-xss-protection", "0"},
                     {"x-frame-options", "SAMEORIGIN"},
                     {"x-content-type-options", "nosniff"},
                     {"alt-svc",
                      "h3-27=\":443\"; ma=2592000,h3-25=\":443\"; ma=2592000,h3-T050=\":443\"; ma=2592000,h3-Q050=\":443\"; ma=2592000,h3-Q049=\":443\"; ma=2592000,h3-Q048=\":443\"; ma=2592000,h3-Q046=\":443\"; ma=2592000,h3-Q043=\":443\"; ma=2592000,quic=\":443\"; ma=2592000; v=\"46,43\""}
                   ],
                   method: :post,
                   opts: [],
                   query: [],
                   status: 404,
                   url:
                     "https://pubsub.googleapis.com/v1/projects/itg-mimercadona/subscriptions/supply-test-juan:pull"
                 }}

  @two_messages {
    :ok,
    %GoogleApi.PubSub.V1.Model.PullResponse{
      receivedMessages: [
        %GoogleApi.PubSub.V1.Model.ReceivedMessage{
          ackId:
            "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVsRDXptXFcnUAwccHxhcm1dEwIBQlJ4W3OK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E",
          message: %GoogleApi.PubSub.V1.Model.PubsubMessage{
            attributes: nil,
            data: "eyJvbmUiOiJ0d28ifQ==",
            messageId: "1152107770337164",
            publishTime: ~U[2020-05-15 18:04:46.791Z]
          }
        },
        %GoogleApi.PubSub.V1.Model.ReceivedMessage{
          ackId:
            "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVoRDXptXFcnUAwccHxhcm9eEwQFRFt-XnOK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E",
          message: %GoogleApi.PubSub.V1.Model.PubsubMessage{
            attributes: %{"att_one" => "one"},
            data: "eyJ0d28iOiJ0aHJlZSJ9",
            messageId: "1152107540571801",
            publishTime: ~U[2020-05-15 18:05:30.225Z]
          }
        }
      ]
    }
  }

  @argument %{
    topic: "test",
    sub: "fake_sub"
  }

  @ack_message {:ok, %GoogleApi.PubSub.V1.Model.Empty{}}

setup do
    {:ok, pubsub_conn: Fixtures.pubsub_conn()}
end

  describe "get messages from pubsub" do
    test "get messages when has not messages to receive", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :get, fn pubsub_conn, "fake_sub" -> @without_messages end)

      {:ok, messages} = PubSubClient.get(pubsub_conn, @argument)

      assert messages == []
    end

    test "get error from pubsub returns the error", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :get, fn conn, "fake_sub" -> @pubsub_error end)

      @pubsub_error = PubSubClient.get(pubsub_conn, @argument)
    end

    test "get messages when has messages to receive", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :get, fn conn, "fake_sub" -> @two_messages end)

      {:ok, messages} = PubSubClient.get(pubsub_conn, @argument)

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
      expect(PubSubMock, :confirm, fn pubsub_conn, ["ackId1", "ackId2"]-> @ack_message end)

      ackIds = ["ackId1", "ackId2"]

      ack_message = PubSubClient.confirm(ackIds, pubsub_conn)

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
