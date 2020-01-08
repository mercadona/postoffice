defmodule PostofficeWeb.Api.PublisherController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Publisher
  alias Postoffice.Messaging

  action_fallback PostofficeWeb.FallbackController

  def create(conn, publisher_params) do
    case Postoffice.receive_publisher(publisher_params) do
      {:ok, publisher} ->
        conn
        |> put_status(:created)
        |> render("show.json", publisher: publisher)

      {:error, errors} ->
        conn
        |> put_status(:bad_request)
        |> render("show.json", changeset: errors)
    end
  end
end
