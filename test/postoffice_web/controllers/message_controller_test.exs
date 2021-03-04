defmodule PostofficeWeb.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures
  alias Postoffice.Messaging

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list failed message" do
    test "can access to messages list", %{conn: conn} do
      conn
      |> get(Routes.message_path(conn, :index))
      |> html_response(200)
    end
  end
end
