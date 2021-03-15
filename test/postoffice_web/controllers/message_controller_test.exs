defmodule PostofficeWeb.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list failed message" do
    test "can access to messages list", %{conn: conn} do
      failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})

      conn
      |> get(Routes.message_path(conn, :index, %{page: 1, page_size: 10}))
      |> html_response(200) =~ to_string(failing_job.id)

      # conn
      # |> get(Routes.message_path(conn, :index))
      # |> html_response(200) =~ Poison.encode!(failing_job.args)
    end
  end
end
