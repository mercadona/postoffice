defmodule PostofficeWeb.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list failed message" do
    test "can access to messages list", %{conn: conn} do
      failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})
      second_failing_job = Fixtures.create_failing_message(%{id: 23, user_id: 2})

      response = conn
      |> get(Routes.message_path(conn, :index, %{page: 1, page_size: 1}))

      assert html_response(response, 200) =~ to_string(failing_job.id)
      refute html_response(response, 200) =~ to_string(second_failing_job.id)

      response = conn
      |> get(Routes.message_path(conn, :index, %{page: 2, page_size: 1}))

      refute html_response(response, 200) =~ to_string(failing_job.id)
      assert html_response(response, 200) =~ to_string(second_failing_job.id)
    end
  end
end
