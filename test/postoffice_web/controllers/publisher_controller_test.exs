defmodule PostofficeWeb.PublisherControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures
  alias Postoffice.Messaging

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list publishers" do
    test "can access to publishers list", %{conn: conn} do
      conn
      |> get(Routes.publisher_path(conn, :index))
      |> html_response(200)
    end

    test "all created publishers are listed", %{conn: conn} do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      conn
      |> get(Routes.publisher_path(conn, :index))
      |> html_response(200) =~ publisher.target
    end
  end

  describe "create publishers" do
    test "can access to publishers list", %{conn: conn} do
      topic = Fixtures.create_topic()

      assert conn
             |> post(
               Routes.publisher_path(conn, :create,
                 publisher: %{
                   target: "http://tar.get",
                   active: "true",
                   type: "http",
                   topic_id: topic.id
                 }
               )
             )
             |> redirected_to() == "/publishers"

      assert Messaging.count_publishers() == 1
    end
  end

  describe "update publishers" do
    test "disable publisher", %{conn: conn} do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      assert conn
             |> put(
               Routes.publisher_path(conn, :update, publisher.id,
                 publisher: %{target: "http://tar.get", active: "false", type: "http"}
               )
             )
             |> redirected_to() == "/publishers"

      saved_publisher = Messaging.get_publisher!(publisher.id)
      assert saved_publisher.active == false
    end

    test "update target", %{conn: conn} do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      assert conn
             |> put(
               Routes.publisher_path(conn, :update, publisher.id,
                 publisher: %{target: "http://new.target", active: "true", type: "http"}
               )
             )
             # |> html_response(200)
             |> redirected_to() == "/publishers"

      saved_publisher = Messaging.get_publisher!(publisher.id)
      assert saved_publisher.target == "http://new.target"
    end

    test "update type", %{conn: conn} do
      topic = Fixtures.create_topic()
      publisher = Fixtures.create_publisher(topic)

      assert conn
             |> put(
               Routes.publisher_path(conn, :update, publisher.id,
                 publisher: %{target: "http://new.target", active: "true", type: "pubsub"}
               )
             )
             |> redirected_to() == "/publishers"

      saved_publisher = Messaging.get_publisher!(publisher.id)
      assert saved_publisher.type == "pubsub"
    end

    test "update topic is not allowed", %{conn: conn} do
      topic = Fixtures.create_topic()
      second_topic = Fixtures.create_topic(%{name: "test2", origin_host: "example2.com"})
      publisher = Fixtures.create_publisher(topic)

      assert conn
             |> put(
               Routes.publisher_path(conn, :update, publisher.id,
                 publisher: %{
                   target: "http://new.target",
                   active: "true",
                   type: "pubsub",
                   topic_id: second_topic.id
                 }
               )
             )
             |> redirected_to() == "/publishers"

      saved_publisher = Messaging.get_publisher!(publisher.id)
      assert saved_publisher.topic_id == topic.id
    end
  end
end
