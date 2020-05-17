defmodule Postoffice.PubSubIngester.PubSubClientTest do
  use ExUnit.Case, async: true

  import Mox

  alias Postoffice.PubSubIngester.Adapters.PubSubMock
  alias Postoffice.PubSubIngester.PubSubClient

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

  describe "get messages from pubsub" do
    test "get messages" do
      expect(PubSubMock, :get, fn "fake_sub" -> @two_messages end)

      {:ok, messages} = PubSubClient.get(@argument)

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
    test "confirm messages returns google response when correct ack" do
      expect(PubSubMock, :confirm, fn ["ackId1", "ackId2"] -> @ack_message end)

      ackIds = ["ackId1", "ackId2"]
      ack_message = PubSubClient.confirm(ackIds)

      assert ack_message == @ack_message
    end
  end
end
