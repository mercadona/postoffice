defmodule PostofficeWeb.Api.PublisherControllerTest do
  use PostofficeWeb.ConnCase

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Repo

  @valid_http_publisher_payload %{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "test",
    type: "http",
    initial_message: 0
  }

  @valid_pubsub_publisher_payload %{
    active: true,
    endpoint: "test",
    topic: "test",
    type: "pubsub",
    initial_message: 0
  }

  @invalid_pubsub_publisher_payload%{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "test",
    type: "pubsub",
    initial_message: 0
  }

  @invalid_http_publisher_payload %{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "fake_topic",
    type: "http",
    initial_message: 0
  }

  @invalid_publisher_endpoint_payload%{
    active: true,
    endpoint: "",
    topic: "test",
    type: "http",
    initial_message: 0
  }


  @invalid_publisher_type_payload %{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "test",
    type: "no_existe",
    initial_message: 0
  }

  @valid_topic_attrs %{
    name: "test"
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create publisher" do
    test "create http publisher when data is valid", %{conn: conn} do
      {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_http_publisher_payload)

      assert json_response(conn, 201)["data"] == %{}
      assert length(Repo.all(Publisher)) == 1
      created_publisher = Messaging.get_last_publisher
      assert created_publisher.active == true
      assert created_publisher.endpoint == "http://fake.endpoint"
      assert created_publisher.initial_message == 0
      assert created_publisher.topic_id == topic.id
      assert created_publisher.type == "http"
    end

    test "create pubsub publisher when data is valid", %{conn: conn} do
      {:ok, topic} = Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_pubsub_publisher_payload)

      assert json_response(conn, 201)["data"] == %{}
      assert length(Repo.all(Publisher)) == 1
      created_publisher = Messaging.get_last_publisher
      assert created_publisher.active == true
      assert created_publisher.endpoint == topic.name
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

    test "renders errors when endpoint is empty", %{conn: conn} do
      Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @invalid_publisher_endpoint_payload)

      assert json_response(conn, 400)["data"] == %{"errors" => %{"endpoint" => ["can't be blank"]}}
      assert length(Repo.all(Publisher)) == 0
    end

    test "renders errors when type is pubsub and endpoint is different that topic", %{conn: conn} do
      Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @invalid_pubsub_publisher_payload)

      assert json_response(conn, 400)["data"] == %{"errors" => %{"endpoint" => ["is invalid"]}}
      assert length(Repo.all(Publisher)) == 0
    end

    test "do not create publisher in case it already exists", %{conn: conn} do
      Messaging.create_topic(@valid_topic_attrs)
      post(conn, Routes.api_publisher_path(conn, :create), @valid_http_publisher_payload)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_http_publisher_payload)

      assert json_response(conn, 400)["data"] == %{"errors" => %{"endpoint" => ["has already been taken"]}}
      assert length(Repo.all(Publisher)) == 1
    end
  end
end
