defmodule PostofficeWeb.Api.PublisherController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Publisher

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, publisher_params) do
    with {:ok, %Publisher{} = publisher} <- Postoffice.receive_publisher(publisher_params) do
      conn
      |> put_status(:created)
      |> render("show.json", publisher: publisher)
    end
  end
end
