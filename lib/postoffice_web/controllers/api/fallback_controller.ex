defmodule PostofficeWeb.Api.FallbackController do
  use PostofficeWeb, :controller

  def call(conn, {:error, changeset}) do
    conn
    |> put_status(:bad_request)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:relationship_does_not_exists, errors}) do
    conn
    |> put_status(:bad_request)
    |> render("error.json", error: errors)
  end
end
