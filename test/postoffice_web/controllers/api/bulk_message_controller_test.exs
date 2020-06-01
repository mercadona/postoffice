defmodule PostofficeWeb.Api.BulkMessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Messaging

  @bulk_create_attrs %{
    payload: [
        %{
        attributes: %{},
        payload: %{"key" => "test1", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
        topic: "test"
      },
      %{
        attributes: %{},
        payload: %{"key" => "test2", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
        topic: "test"
      }
    ]
  }

  @wrong_topic_create_attrs %{
    payload: [
        %{
        attributes: %{},
        payload: %{"key" => "test1", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
        topic: "test2"
      }
    ]
  }


  setup %{conn: conn} do
    {:ok, _topic} = Messaging.create_topic(%{name: "test", origin_host: "example.com"})
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create bulk message" do
    test "accept more than one message", %{conn: conn} do
      conn = post(conn, Routes.api_bulk_message_path(conn, :create), @bulk_create_attrs)

      assert json_response(conn, 201)
      assert Kernel.length(Messaging.list_messages) == 2
    end

    test "returns error in case something wrong happens during insert", %{conn: conn} do
      conn = post(conn, Routes.api_bulk_message_path(conn, :create), @wrong_topic_create_attrs)

      assert json_response(conn, 406)
    end
  end
end
