defmodule PostofficeWeb.Api.PublisherControllerTest do
  use PostofficeWeb.ConnCase

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Repo

  @valid_attrs %{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "test",
    type: "http",
    initial_message: 0
  }
  @invalid_attrs %{
    active: true,
    endpoint: "http://fake.endpoint",
    topic: "no_existe",
    type: "http",
    initial_message: 0
  }
  @invalid_attrs_2 %{
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
    test "create publisher when data is valid", %{conn: conn} do
      {:ok, _topic} = Messaging.create_topic(@valid_topic_attrs)
      conn = post(conn, Routes.api_publisher_path(conn, :create), @valid_attrs)

      assert json_response(conn, 201)["data"] == %{}
      assert length(Repo.all(Publisher)) == 1
    end

    test "renders errors when topic does not exists", %{conn: conn} do
      conn = post(conn, Routes.api_publisher_path(conn, :create), @invalid_attrs)
      assert json_response(conn, 400)["data"] == %{"errors" => %{"topic" => ["is invalid"]}}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      {:ok, _topic} = Messaging.create_topic(@valid_topic_attrs)

      conn = post(conn, Routes.api_publisher_path(conn, :create), @invalid_attrs_2)

      assert json_response(conn, 400)["data"] == %{"errors" => %{"type" => ["is invalid"]}}
      assert length(Repo.all(Publisher)) == 0
    end

    # test "do not create topic in case it already exists", %{conn: conn} do
    #   {:ok, existing_topic} = Messaging.create_topic(%{name: "test"})
    #   conn = post(conn, Routes.api_topic_path(conn, :create), topic: @create_attrs)
    #   new_topic = json_response(conn, 201)["data"]
    #   assert new_topic["id"] == existing_topic.id
    # end
  end
end

