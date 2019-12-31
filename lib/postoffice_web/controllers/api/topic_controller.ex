defmodule PostofficeWeb.Api.TopicController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Topic

  action_fallback PostofficeWeb.FallbackController

  def create(conn, %{"topic" => topic_params}) do
    changeset = Topic.changeset(%Topic{}, topic_params)
    case changeset.valid? do
      true ->
        {:ok, topic} = Postoffice.create_topic(topic_params)
        conn
        |> put_status(:created)
        |> render("show.json", topic: topic )
      false ->
        conn
        |> put_status(:bad_request)
        |> render("show.json", changeset: changeset )
    end
  end
end
