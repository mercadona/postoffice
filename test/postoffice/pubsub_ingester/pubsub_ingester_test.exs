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

  setup do
    {:ok, pubsub_conn: Fixtures.pubsub_conn()}
  end

  @acks_ids [
    "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVsRDXptXFcnUAwccHxhcm1dEwIBQlJ4W3OK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E",
    "ISE-MD5FU0RQBhYsXUZIUTcZCGhRDk9eIz81IChFEAcGTwIoXXkyVSFBXBoHUQ0Zcnxmd2tTGwMKEwUtVVoRDXptXFcnUAwccHxhcm9eEwQFRFt-XnOK75niloGyYxclSoGxxaxvM7nUxvhMZho9XhJLLD5-MjVFQV5AEkw5AERJUytDCypYEU4E"
  ]

  @argument %{
    topic: "test",
    sub: "fake_sub"
  }

  describe "pubsub ingester" do
    test "no message created on error", %{pubsub_conn: pubsub_conn} do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      expect(PubSubMock, :connect, fn -> pubsub_conn end)
      expect(PubSubMock, :get, fn  _pubsub_conn, "fake_sub" -> Fixtures.pubsub_error() end)
      expect(PubSubMock, :confirm, 0, fn  _pubsub_conn, "fake_sub", @acks_ids -> Fixtures.google_ack_message() end)

      PubSubIngester.run(@argument)

      assert Messaging.list_messages() == []
    end

    test "no message created if no undelivered message found", %{pubsub_conn: pubsub_conn} do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      expect(PubSubMock, :connect, fn -> pubsub_conn end)
      expect(PubSubMock, :get, fn  _pubsub_conn, "fake_sub" -> Fixtures.empty_google_pubsub_messages() end)
      expect(PubSubMock, :confirm, 0, fn  _pubsub_conn, "fake_sub", @acks_ids -> Fixtures.google_ack_message() end)

      PubSubIngester.run(@argument)

      assert Messaging.list_messages() == []
    end

    test "create message when is ingested", %{pubsub_conn: pubsub_conn} do
      topic = Fixtures.create_topic()
      Fixtures.create_publisher(topic)

      expect(PubSubMock, :connect, fn -> pubsub_conn end)
      expect(PubSubMock, :get, fn  _pubsub_conn, "fake_sub" -> Fixtures.two_google_pubsub_messages() end)
      expect(PubSubMock, :confirm, fn  _pubsub_conn, "fake_sub", @acks_ids -> Fixtures.google_ack_message() end)

      PubSubIngester.run(@argument)

      assert length(Repo.all(PendingMessage)) == 2
    end

    test "Do not ack when postoffice topic does not exists", %{pubsub_conn: pubsub_conn} do
      expect(PubSubMock, :connect, fn -> pubsub_conn end)
      expect(PubSubMock, :get, fn  _pubsub_conn, "fake_sub" -> Fixtures.two_google_pubsub_messages() end)
      expect(PubSubMock, :confirm, 0, fn  _pubsub_conn, "fake_sub", @acks_ids -> Fixtures.google_ack_message() end)

      assert_raise MatchError, fn ->
        PubSubIngester.run(@argument)
      end
    end
  end
end
