defmodule PostofficeWeb.Api.TopicControllerTest do
  use PostofficeWeb.ConnCase

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Topic
  alias Postoffice.Repo

  @create_attrs %{
    name: "test"
  }
  @invalid_attrs %{name: ""}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create topic" do
    test "renders created topic information when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), @create_attrs)
      created_topic = json_response(conn, 201)["data"]
      assert created_topic["name"] == "test"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), @invalid_attrs)
      assert json_response(conn, 400)["data"]["errors"] == %{"name" => ["can't be blank"]}
    end

    test "do not create topic in case it already exists", %{conn: conn} do
      {:ok, _topic} = Messaging.create_topic(@create_attrs)

      conn = post(conn, Routes.api_topic_path(conn, :create), @create_attrs)

      assert json_response(conn, 400)["data"] == %{
               "errors" => %{"name" => ["has already been taken"]}
             }

      assert length(Repo.all(Topic)) == 1
    end
  end
end
