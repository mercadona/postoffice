defmodule Postoffice.HttpWorkerTest do
  use Postoffice.DataCase, async: true
  use Oban.Testing, repo: Postoffice.Repo

  import Mox

  alias GoogleApi.PubSub.V1.Model.PublishResponse
  alias Postoffice.Adapters.HttpMock
  alias Postoffice.Adapters.PubsubMock
  alias Postoffice.HttpWorker
  alias Postoffice.Fixtures
  alias Postoffice.HistoricalData

  setup [:set_mox_from_context, :verify_on_exit!]

  @deleted_publisher_attrs %{
    active: true,
    target: "http://fake.target3",
    initial_message: 0,
    type: "http",
    deleted: true
  }

  describe "HttpWorker tests" do
    test "message is successfully sent" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expected_args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(HttpMock, :publish, fn _id, ^expected_args ->
        {:ok, %HTTPoison.Response{status_code: 201}}
      end)

      expect(PubsubMock, :publish, fn  _, _ ->
        {:ok, %PublishResponse{}}
      end)

      assert {:ok, _sent} = perform_job(HttpWorker, args)
    end

    test "historical data is created when message is sent" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expected_args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(HttpMock, :publish, fn _id, ^expected_args ->
        {:ok, %HTTPoison.Response{status_code: 201}}
      end)

      expected_pubsub_args = %{
        "consumer_id" => publisher.id,
        "target" => "postoffice-sent-messages",
        "payload" => %{
          "consumer_id" => publisher.id,
          "target" => publisher.target,
          "type" => publisher.type,
          "message_payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
          "attributes" => %{"hive_id" => "vlc"},
        },
        "attributes" => %{"cluster_name" => "vlc"}
      }

      expect(PubsubMock, :publish, fn  _id, ^expected_pubsub_args ->
        {:ok, %PublishResponse{}}
      end)

      perform_job(HttpWorker, args)
      assert Kernel.length(HistoricalData.list_sent_messages()) == 0

    end

    test "message is not send if response code is out of 2xx range" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expected_args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(HttpMock, :publish, fn _id, ^expected_args ->
        {:ok, %HTTPoison.Response{status_code: 302}}
      end)

      expect(PubsubMock, :publish, 0, fn  _id, ^expected_args ->
        {:ok, %PublishResponse{}}
      end)

      assert {:error, :nosent} = perform_job(HttpWorker, args)
    end

    test "historical data is created when message response is out of 2xx range" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expected_args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(HttpMock, :publish, fn _id, ^expected_args ->
        {:ok, %HTTPoison.Response{status_code: 302}}
      end)

      perform_job(HttpWorker, args)
      assert Kernel.length(HistoricalData.list_failed_messages()) == 1
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

      expected_args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(HttpMock, :publish, fn _id, ^expected_args ->
        {:error, %HTTPoison.Error{reason: "Fake error"}}
      end)

      assert {:error, :nosent} = perform_job(HttpWorker, args)
    end

    test "historical data is created when message response if there is any error on the request" do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test"},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expected_args = %{
        "consumer_id" => publisher.id,
        "target" => publisher.target,
        "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
        "attributes" => %{"hive_id" => "vlc"}
      }

      expect(HttpMock, :publish, fn _id, ^expected_args ->
        {:error, %HTTPoison.Error{reason: "Fake error"}}
      end)

      perform_job(HttpWorker, args)
      assert Kernel.length(HistoricalData.list_failed_messages()) == 1
    end
  end

  test "We have 100 attempts for an http job" do
    topic = Fixtures.create_topic()
    publisher = Fixtures.create_publisher(topic)

    args = %{
      "consumer_id" => publisher.id,
      "target" => publisher.target,
      "payload" => %{"action" => "test"},
      "attributes" => %{"hive_id" => "vlc"}
    }

    expected_args = %{
      "consumer_id" => publisher.id,
      "target" => publisher.target,
      "payload" => %{"action" => "test", "attributes" => %{"hive_id" => "vlc"}},
      "attributes" => %{"hive_id" => "vlc"}
    }

    expect(HttpMock, :publish, fn _id, ^expected_args ->
      {:ok, %HTTPoison.Response{status_code: 201}}
    end)

    expect(PubsubMock, :publish, fn  _, _ ->
      {:ok, %PublishResponse{}}
    end)

    assert {:ok, _sent} = perform_job(HttpWorker, args, attempt: 100)
  end

  test "not sent message when worker is deleted" do
    topic = Fixtures.create_topic()
    publisher = Fixtures.create_publisher(topic, @deleted_publisher_attrs)
    Cachex.put(:postoffice, publisher.id, :deleted)

    args = %{
      "consumer_id" => publisher.id,
      "target" => publisher.target,
      "payload" => %{"action" => "test"},
      "attributes" => %{"hive_id" => "vlc"}
    }

    assert {:discard, "Deleted publisher"} = perform_job(HttpWorker, args)

    assert Kernel.length(all_enqueued(queue: :http)) == 0
    assert Kernel.length(HistoricalData.list_sent_messages()) == 0
    assert Kernel.length(HistoricalData.list_failed_messages()) == 0
  end
end
