defmodule Postoffice.Fixtures do
  @moduledoc """
  This module defines the shared fixtures between the tests
  """
  alias Postoffice
  alias Postoffice.Messaging
  alias Postoffice.Repo

  @topic_attrs %{
    name: "test",
    origin_host: "example.com",
    recovery_enabled: true
  }

  @message_attrs %{
    attributes: %{},
    payload: %{},
    public_id: "7488a646-e31f-11e4-aace-600308960662"
  }

  @publisher_attrs %{
    active: true,
    target: "http://fake.target",
    initial_message: 0,
    type: "http"
  }

  def add_message_to_deliver(topic, attrs \\ @message_attrs) do
    {:ok, message} = Messaging.add_message_to_deliver(topic, attrs)

    message
  end

  def create_topic(attrs \\ @topic_attrs) do
    {:ok, topic} = Messaging.create_topic(attrs)
    topic
  end

  def create_publisher(topic, attrs \\ @publisher_attrs) do
    {:ok, publisher} = Messaging.create_publisher(Map.put(attrs, :topic_id, topic.id))
    publisher
  end

  def create_publisher_success(message, publisher) do
    {:ok, _publisher_success} =
      Messaging.create_publisher_success(%{message_id: message.id, publisher_id: publisher.id})
      |> Repo.insert()
  end

  def create_publishers_failure(message, publisher) do
    {:ok, _publisher_success} =
      Messaging.create_publisher_failure(%{message_id: message.id, publisher_id: publisher.id})
  end

  def pubsub_conn(),
    do: %Tesla.Client{
      adapter: nil,
      fun: nil,
      post: [],
      pre: [
        {Tesla.Middleware.Headers, :call,
         [
           [
             {"authorization",
              "Bearer ya29.c.Ko8BywcJmQ044Tz44v_NoMQ03cXByM1rMjKSFKBWpjcCE2RLIDlxlWvlSXC8gSYtQTmdkRi-wA-mzFsSn37l1uV7TlbHq5rIqqdDbr746sECtpT5vF1JEskVLC2VsEBc-ukAT4C8hb-n1xXLw00S2M5kCBANtdSsbkeTG1I57fuIGN3dU3TSKtRzmZ0on5Anlgs"}
           ]
         ]}
      ]
    }

  def empty_google_pubsub_messages(),
    do: {:ok, %GoogleApi.PubSub.V1.Model.PullResponse{receivedMessages: nil}}

  def two_google_pubsub_messages(),
    do: {
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

  def google_ack_message(),
    do: {:ok, %GoogleApi.PubSub.V1.Model.Empty{}}

  def pubsub_error(),
    do:
      {:error,
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
end
