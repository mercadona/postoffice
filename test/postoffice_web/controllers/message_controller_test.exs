defmodule PostofficeWeb.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list failed message" do
    test "can access to messages list", %{conn: conn} do
      failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})

      response = conn
      |> get(Routes.message_path(conn, :index, %{page: 1, page_size: 100}))

      assert html_response(response, 200) =~ to_string(failing_job.id)
    end
  end
end
