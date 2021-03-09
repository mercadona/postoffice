defmodule PostofficeWeb.MessageControllerTest do
  use PostofficeWeb.ConnCase, async: true

  alias Postoffice.Fixtures
  alias Postoffice.Messaging
  alias Postoffice.Repo
  import Ecto.Changeset

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  describe "list failed message" do
    test "can access to messages list", %{conn: conn} do
      data = %{id: 1, user_id: 2}

      {:ok, oban} =
        Oban.Job.new(data, queue: :http, worker: Postoffice.SomeFakeWorker)
        |> Repo.insert()

      {:ok, mec} =
        Repo.get(Oban.Job, oban.id)
        |> change(%{state: "retryable"})
        |> Repo.update()

      conn
      |> get(Routes.message_path(conn, :index))
      |> html_response(200) =~ to_string(mec.id)

      conn
      |> get(Routes.message_path(conn, :index))
      |> html_response(200) =~ Poison.encode!(mec.args)
    end
  end
end
