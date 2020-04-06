defmodule PostofficeWeb.Api.PublisherControllerTest do
  use PostofficeWeb.ConnCase, async: true

  import Ecto.Query, warn: false

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Repo

  @valid_http_publisher_payload %{
    active: true,
    target: "http://fake.target",
    topic: "test",
    type: "http",
    initial_message: 0
  }

  @valid_pubsub_publisher_payload %{
    active: true,
    target: "test",
    topic: "test",
    type: "pubsub",
    initial_message: 0
  }

  @invalid_http_publisher_payload %{
    active: true,
    target: "http://fake.target",
    topic: "fake_topic",
    type: "http",
    initial_message: 0
  }

  @invalid_publisher_target_payload %{
    active: true,
    target: "",
    topic: "test",
    type: "http",
    initial_message: 0
  }

  @invalid_publisher_type_payload %{
    active: true,
    target: "http://fake.target",
    topic: "test",
    type: "false_type",
    initial_message: 0
  }

  @valid_topic_attrs %{
    name: "test",
    origin_host: "example.com"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp get_last_publisher() do
    from(p in Publisher, order_by: [desc: :id], limit: 1)
    |> Repo.one()
  end

  describe "create publisher" do
    test "create http publisher when data is valid", %{conn: conn} do
      {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_http_publisher_payload)

      assert json_response(conn, 201)["data"] == %{}
      assert length(Repo.all(Publisher)) == 1
      created_publisher = get_last_publisher()
      assert created_publisher.active == true
      assert created_publisher.target == "http://fake.target"
      assert created_publisher.initial_message == 0
      assert created_publisher.topic_id == topic.id
      assert created_publisher.type == "http"
    end

    test "create pubsub publisher when data is valid", %{conn: conn} do
      {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_pubsub_publisher_payload)

      assert json_response(conn, 201)["data"] == %{}
      assert length(Repo.all(Publisher)) == 1

      created_publisher = get_last_publisher()
      assert created_publisher.active == true
      assert created_publisher.target == topic.name
      assert created_publisher.initial_message == 0
      assert created_publisher.topic_id == topic.id
      assert created_publisher.type == "pubsub"
    end

    test "renders errors when topic does not exists", %{conn: conn} do
      conn = post(conn, Routes.api_publisher_path(conn, :create), @invalid_http_publisher_payload)

      assert json_response(conn, 400)["data"] == %{"errors" => %{"topic" => ["is invalid"]}}
    end

    test "renders errors when type does not exists", %{conn: conn} do
      Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @invalid_publisher_type_payload)

      assert json_response(conn, 400)["data"] == %{"errors" => %{"type" => ["is invalid"]}}
      assert length(Repo.all(Publisher)) == 0
    end

    test "renders errors when target is empty", %{conn: conn} do
      Messaging.create_topic(@valid_topic_attrs)

      conn =
        post(conn, Routes.api_publisher_path(conn, :create), @invalid_publisher_target_payload)

      assert json_response(conn, 400)["data"] == %{
               "errors" => %{"target" => ["can't be blank"]}
             }

      assert length(Repo.all(Publisher)) == 0
    end

    test "do not create publisher in case it already exists", %{conn: conn} do
      Messaging.create_topic(@valid_topic_attrs)
      post(conn, Routes.api_publisher_path(conn, :create), @valid_http_publisher_payload)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_http_publisher_payload)

      assert json_response(conn, 409)["data"] == %{
               "errors" => %{"target" => ["has already been taken"]}
             }

      assert length(Repo.all(Publisher)) == 1
    end
  end
end
