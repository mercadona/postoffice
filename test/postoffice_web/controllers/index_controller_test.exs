defmodule PostofficeWeb.IndexControllerTest do
  use PostofficeWeb.ConnCase, async: true

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "index dashboard" do
    test "can access", %{conn: conn} do
      conn =
        conn
        |> get(Routes.dashboard_path(conn, :index))

      assert html_response(conn, 200)
    end
  end
end
