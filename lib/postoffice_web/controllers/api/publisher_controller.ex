defmodule PostofficeWeb.Api.PublisherController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging.Publisher
  alias Postoffice.Messaging

  action_fallback PostofficeWeb.FallbackController

  def create(conn, %{"topic" => topic} = publisher_params) do
    topic = Messaging.get_topic(topic)

    publisher =Map.put(publisher_params, "topic_id", topic.id)

    changeset = Publisher.changeset(%Publisher{}, publisher)

    case changeset.valid? do
      true ->
        {:ok, topic} = Postoffice.create_publisher(publisher)

        conn
        |> put_status(:created)
        |> render("show.json", publisher: publisher)

      false ->
        conn
        |> put_status(:bad_request)
        |> render("show.json", changeset: changeset)
    end
  end
end
