defmodule PostofficeWeb.Api.BulkMessageControllerTest do
  use PostofficeWeb.ConnCase, async: true
  use Oban.Testing, repo: Postoffice.Repo

  alias Postoffice.Messaging
  alias Postoffice.Fixtures

  @wrong_topic_create_attrs %{
    attributes: %{},
    payload: %{"key" => "test1", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    topic: "test2"
  }

  @create_attrs %{
    attributes: %{},
    payload: [
      %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
      %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]}
    ],
    topic: "test"
  }

  @exceed_max_ingestion_messages_attrs %{
    attributes: %{},
    payload: [
      %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
      %{"key" => "test", "key_list" => [%{"letter" => "c"}, %{"letter" => "d"}]},
      %{"key" => "test", "key_list" => [%{"letter" => "e"}, %{"letter" => "f"}]},
      %{"key" => "test", "key_list" => [%{"letter" => "g"}, %{"letter" => "h"}]}
    ],
    topic: "test"
  }

  setup %{conn: conn} do
    {:ok, topic} = Messaging.create_topic(%{name: "test", origin_host: "example.com"})
    Fixtures.create_publisher(topic)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create bulk message" do
    test "accept more than one message", %{conn: conn} do
      conn = post(conn, Routes.api_bulk_message_path(conn, :create), @create_attrs)

      assert json_response(conn, 201)
      assert Kernel.length(all_enqueued(queue: :http)) == 2
    end

    test "returns error in case something wrong happens during insert", %{conn: conn} do
      conn = post(conn, Routes.api_bulk_message_path(conn, :create), @wrong_topic_create_attrs)

      assert json_response(conn, 406)
    end

    test "returns error when ingest more messages than max_bulk_messages", %{conn: conn} do
      conn =
        post(
          conn,
          Routes.api_bulk_message_path(conn, :create),
          @exceed_max_ingestion_messages_attrs
        )

      assert json_response(conn, 406)
      assert Kernel.length(all_enqueued(queue: :http)) == 0
    end
  end
end
