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

  @acks_ids ["ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVsRDXptXFcnUAwccHxhcm1dEwIBQlJ4W3OK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E", "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVoRDXptXFcnUAwccHxhcm9eEwQFRFt-XnOK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E"]

  @without_messages {:ok, %GoogleApi.PubSub.V1.Model.PullResponse{receivedMessages: nil}}

  @argument %{
        topic: "test",
        sub: "fake_sub"
      }

  @ack_message {:ok, %GoogleApi.PubSub.V1.Model.Empty{}}

  describe "pubsub ingester" do
    test "no message created if subscription does not exists" do
      assert 1 == 2
    end

    test "do not ack message on error" do
      assert 1 == 2
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
  end
end
