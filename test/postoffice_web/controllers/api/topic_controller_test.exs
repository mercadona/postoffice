defmodule PostofficeWeb.Api.TopicControllerTest do
  use PostofficeWeb.ConnCase

  alias Postoffice.Messaging

  @create_attrs %{
    name: "test"
  }
  @invalid_attrs %{invalid_key: "invalid"}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create topic" do
    test "renders topic when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), topic: @create_attrs)
      created_topic = json_response(conn, 201)["data"]
      assert created_topic["name"] == "test"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), topic: @invalid_attrs)
      assert json_response(conn, 400)["errors"] != %{}
    end

    test "do not create topic in case it already exists", %{conn: conn} do
      {:ok, topic} = Messaging.create_topic(%{name: "test"})
      conn = post(conn, Routes.api_topic_path(conn, :create), topic: @create_attrs)
      created_topic = json_response(conn, 201)["data"]
      assert created_topic["id"] == topic.id
    end
  end
end
