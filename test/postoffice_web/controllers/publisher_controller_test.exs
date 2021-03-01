defmodule PostofficeWeb.PublisherControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Phoenix.PubSub

  setup do
    Ecto.Adapters.SQL.Sandbox.mode(Postoffice.Repo, {:shared, self()})
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

  describe "Delete publisher" do
    test "delete a publisher", %{conn: conn} do
      topic = Fixtures.create_topic()
      second_topic = Fixtures.create_topic(%{name: "test2", origin_host: "example2.com"})
      publisher = Fixtures.create_publisher(topic)

      assert conn
      |> delete(Routes.publisher_path(conn, :delete, publisher.id))
      |> redirected_to() == "/publishers"

      deleted_publisher = Messaging.get_publisher!(publisher.id)
      assert deleted_publisher.deleted == true
    end

    test "Delete publisher broadcast the publisher updated", %{conn: conn} do
      PubSub.subscribe(Postoffice.PubSub, "publishers")

      publisher =
        Fixtures.create_topic()
        |> Fixtures.create_publisher()

      conn = delete(conn, Routes.publisher_path(conn, :delete, publisher))

      assert_receive {:publisher_deleted, publisher}
    end

  end
end
