defmodule PostofficeWeb.Api.FallbackController do
  use PostofficeWeb, :controller

  def call(conn, {:error, changeset}) do
    status = select_status(changeset.errors)

    conn
    |> put_status(status)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:relationship_does_not_exists, errors}) do
    conn
    |> put_status(:bad_request)
    |> render("error.json", error: errors)
  end

  def call(conn, {:deleting_error}) do
    conn
    |> put_status(:bad_request)
    |> render("error.json", error: "Anything has wrong")
  end

  defp select_status(errors) do
    case violate_unique_constraint(errors) do
      true ->
        :conflict

      _ ->
        :bad_request
    end
  end

  defp violate_unique_constraint(errors) do
    Enum.find_value(errors, fn error ->
      error
      |> elem(1)
      |> elem(1)
      |> Enum.find_value(fn type ->
        type
        |> elem(1) == :unique
      end)
    end)
  end
end
