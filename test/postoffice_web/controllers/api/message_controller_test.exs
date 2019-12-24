defmodule PostofficeWeb.Api.MessageControllerTest do
  use PostofficeWeb.ConnCase

  alias Postoffice.Messaging

  @create_attrs %{
    attributes: %{},
    payload: %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    topic: "test"
  }
  @invalid_attrs %{attributes: nil, payload: nil, topic: "test"}

  def fixture(:message) do
    {:ok, topic} = Messaging.create_topic(%{name: "test", id: 1})
    {:ok, message} = Messaging.create_message(topic, @create_attrs)
    message
  end

  setup %{conn: conn} do
    {:ok, _topic} = Messaging.create_topic(%{name: "test"})
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all messages", %{conn: conn} do
      conn = get(conn, Routes.api_message_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create message" do
    test "renders message when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_message_path(conn, :create), message: @create_attrs)
      assert %{"public_id" => id} = json_response(conn, 201)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.api_message_path(conn, :create), message: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
