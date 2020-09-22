defmodule PostofficeWeb.Api.ScheduleMessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Messaging

  @create_attrs %{
    attributes: %{},
    payload: %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    topic: "test",
    schedule_at: "2100-12-31 10:11:12.131415"
  }

  @wrong_payload_without_topic %{
    attributes: %{},
    payload: %{"key" => "test", "key_list" => [%{"letter" => "a"}, %{"letter" => "b"}]},
    schedule_at: "2100-12-31 10:11:12.131415",
    topic: "wrong_topic"
  }

  setup %{conn: conn} do
    {:ok, _topic} = Messaging.create_topic(%{name: "test", origin_host: "example.com"})
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "schedule message" do
    test "returns 201 when data is valid", %{conn: conn} do
      conn = post(conn, Routes.api_schedule_message_path(conn, :create), @create_attrs)
      assert json_response(conn, 201)
    end

    test "renders errors when topic does not exists", %{conn: conn} do
      conn =
        post(conn, Routes.api_schedule_message_path(conn, :create), @wrong_payload_without_topic)

      assert json_response(conn, 400)["data"]["errors"] == %{"topic" => ["is invalid"]}
    end
  end
end
