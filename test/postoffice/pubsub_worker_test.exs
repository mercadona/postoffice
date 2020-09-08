defmodule Postoffice.PubsubWorkerTest do
  use Postoffice.DataCase, async: true
  use Oban.Testing, repo: Postoffice.Repo

  import Mox

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Adapters.PubsubMock
  alias Postoffice.PubsubWorker
  alias Postoffice.Fixtures
  alias Postoffice.HistoricalData

  setup [:set_mox_from_context, :verify_on_exit!]

  describe "PubsubWorker tests" do
    test "message is successfully sent" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(PubsubMock, :publish, fn _id, ^args ->
        {:ok, %PublishResponse{}}
      end)

      assert {:ok, sent} = perform_job(PubsubWorker, args)
    end

    test "historical data is created if message is successfully sent" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(PubsubMock, :publish, fn _id, ^args ->
        {:ok, %PublishResponse{}}
      end)

      perform_job(PubsubWorker, args)
      assert Kernel.length(HistoricalData.list_sent_messages()) == 1
    end

    test "message is not send if there is any error on the request" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(PubsubMock, :publish, fn _id, ^args ->
        {:error, "fake error"}
      end)

      assert {:error, :nosent} = perform_job(PubsubWorker, args)
    end

    test "historical data is created if message is not send" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(PubsubMock, :publish, fn _id, ^args ->
        {:error, "fake error"}
      end)

      perform_job(PubsubWorker, args)
      assert Kernel.length(HistoricalData.list_failed_messages()) == 1
    end
  end
end
