defmodule PostofficeWeb.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.Repo

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "failing messages" do
    test "can access to messages list", %{conn: conn} do
      failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})

      response = conn
      |> get(Routes.message_path(conn, :index, %{page: 1, page_size: 100}))

      assert html_response(response, 200) =~ to_string(failing_job.id)
    end

    test "cancel failing message job", %{conn: conn} do
      failing_job = Fixtures.create_failing_message(%{id: 1, user_id: 2})

      assert conn
      |> delete(Routes.message_path(conn, :delete, failing_job.id))
      |> redirected_to() == "/messages"

      deleted_failing_job = Repo.get(Oban.Job, failing_job.id)
      assert deleted_failing_job.state == "cancelled"
    end

  end
end
