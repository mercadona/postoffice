defmodule Postoffice.PubSubIngester.PubSubIngesterTest do
  use Postoffice.DataCase, async: true
  use ExUnit.Case, async: true

  import Mox

  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.Messaging.PendingMessage
  alias Postoffice.PubSubIngester.PubSubIngester
  alias Postoffice.PubSubIngester.Adapters.PubSubMock

  setup [:set_mox_from_context, :verify_on_exit!]

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

  @acks_ids [
    "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVsRDXptXFcnUAwccHxhcm1dEwIBQlJ4W3OK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E",
    "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVoRDXptXFcnUAwccHxhcm9eEwQFRFt-XnOK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E"
  ]

  @without_messages {:ok, %GoogleApi.PubSub.V1.Model.PullResponse{receivedMessages: nil}}

  @argument %{
    topic: "test",
    sub: "fake_sub"
  }

  @ack_message {:ok, %GoogleApi.PubSub.V1.Model.Empty{}}

  describe "pubsub ingester" do
    test "no message created on error" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      expect(PubSubMock, :get, fn "fake_sub" -> @pubsub_error end)
      expect(PubSubMock, :confirm, 0, fn @acks_ids -> @ack_message end)

      PubSubIngester.run(@argument)

      assert Messaging.list_messages() == []
    end

    test "no message created if no undelivered message found" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      expect(PubSubMock, :get, fn "fake_sub" -> @without_messages end)
      expect(PubSubMock, :confirm, 0, fn @acks_ids -> @ack_message end)

      PubSubIngester.run(@argument)

      assert Messaging.list_messages() == []
    end

    test "create message when is ingested" do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      expect(PubSubMock, :get, fn "fake_sub" -> @two_messages end)
      expect(PubSubMock, :confirm, fn @acks_ids -> @ack_message end)

      PubSubIngester.run(@argument)

      assert length(Repo.all(PendingMessage)) == 2
    end

    test "Do not ack when postoffice topic does not exists" do
      expect(PubSubMock, :get, fn "fake_sub" -> @two_messages end)
      expect(PubSubMock, :confirm, 0, fn @acks_ids -> @ack_message end)

      assert_raise MatchError, fn ->
        PubSubIngester.run(@argument)
      end
    end
  end
end
