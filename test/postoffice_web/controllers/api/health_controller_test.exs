defmodule PostofficeWeb.Api.HealthControllerTest do
  use PostofficeWeb.ConnCase, async: true

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "Health check api endpoint" do
    test "ok when app is up&running", %{conn: conn} do
      conn = get(conn, Routes.api_health_path(conn, :index))

      assert json_response(conn, 200) == %{"status" => "ok"}
    end
  end
end
