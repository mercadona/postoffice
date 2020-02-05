defmodule PostofficeWeb.TopicControllerTest do
  use PostofficeWeb.ConnCase

  alias Postoffice.Fixtures

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list topics" do
    test "can access to topics list", %{conn: conn} do

      conn
      |> get(Routes.topic_path(conn, :index))
      |> html_response(200)
    end

    test "all created topics are listed", %{conn: conn} do
      topic = Fixtures.create_topic()

      conn
      |> get(Routes.topic_path(conn, :index))
      |> html_response(200) =~ topic.name
    end
  end

  describe "create topics" do
    test "can access to topics list", %{conn: conn} do

      assert conn
      |> post(Routes.topic_path(conn, :create, [topic: %{name: "Test Topic", origin_host: "example.com"}]))
      |> redirected_to() == "/topics"
    end
  end
end
