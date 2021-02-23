defmodule PostofficeWeb.Api.PublisherController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Publisher
  alias Postoffice.Messaging

  action_fallback PostofficeWeb.Api.FallbackController

  def create(conn, publisher_params) do
    with {:ok, %Publisher{} = publisher} <- Postoffice.receive_publisher(publisher_params) do
      conn
      |> put_status(:created)
      |> render("show.json", publisher: publisher)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Messaging.get_publisher!(id) do
      nil ->
        {:deleting_error}

      publisher ->
        publisher
        |> Publisher.changeset(%{deleted: true})
        |> Messaging.update_publisher()

        send_resp(conn, :no_content, "")
    end
  end
end
