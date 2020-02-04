defmodule PostofficeWeb.Api.TopicControllerTest do
  use PostofficeWeb.ConnCase

  import Ecto.Query, warn: false

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Topic
  alias Postoffice.Repo

  @create_attrs %{
    name: "test",
    origin_host: "example.com"
  }

  @topic_without_name %{name: "", origin_host: "example.com"}
  @topic_without_origin_host %{name: "test", origin_host: ""}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  defp get_last_topic() do
    from(t in Topic, order_by: [desc: :id], limit: 1)
    |> Repo.one()
  end

  describe "create topic" do
    test "renders created topic information when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), @create_attrs)
      created_topic = json_response(conn, 201)["data"]
      assert created_topic["name"] == "test"
    end

    test "creates the topic when data is valid", %{conn: conn} do
      conn
      |> post(Routes.api_topic_path(conn, :create), @create_attrs)

      created_topic = get_last_topic()

      assert created_topic.name == "test"
      assert created_topic.origin_host == "example.com"
    end

    test "renders errors when name is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), @topic_without_name)
      assert json_response(conn, 400)["data"]["errors"] == %{"name" => ["can't be blank"]}
    end

    test "renders errors when origin_host is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_topic_path(conn, :create), @topic_without_origin_host)
      assert json_response(conn, 400)["data"]["errors"] == %{"origin_host" => ["can't be blank"]}
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
