defmodule PostofficeWeb.PublisherController do
  use PostofficeWeb, :controller

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Publisher

  def new(conn, _params) do
    changeset = Publisher.changeset(%Publisher{}, %{})

    topics =
      Messaging.list_topics()
      |> Enum.map(&{"#{&1.name}", &1.id})

    render(conn, "new.html", changeset: changeset, topics: topics, page_name: "Add publisher")
  end

  def create(conn, %{"publisher" => publisher_params}) do
    {:ok, publisher} = Postoffice.create_publisher(publisher_params)

    conn
    |> put_flash(:info, "Publisher #{publisher.id} created!")
    |> redirect(to: Routes.publisher_path(conn, :index))
  end

  def index(conn, _params) do
    publishers = Messaging.list_publishers()
    render(conn, "index.html", publishers: publishers, page_name: "Publishers")
  end

  def edit(conn, %{"id" => id}) do
    publisher = Messaging.get_publisher!(id)
    changeset = Messaging.change_publisher(publisher)

    topics =
      Messaging.list_topics()
      |> Enum.map(&{"#{&1.name}", &1.id})

    render(conn, "edit.html",
      publisher: publisher,
      changeset: changeset,
      topics: topics,
      page_name: "Edit publishers"
    )
  end

  def update(conn, %{"id" => id, "publisher" => publisher_params}) do
    publisher = Messaging.get_publisher!(id)
    {_key, publisher_params} = Map.pop(publisher_params, "topic_id")

    publisher
    |> Publisher.changeset(publisher_params)
    |> Messaging.update_publisher()
    |> case do
      {:ok, _publisher} ->
        conn
        |> put_flash(:info, "http_consumer updated successfully.")
        |> redirect(to: Routes.publisher_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", publisher: publisher, changeset: changeset)
    end
  end
end
