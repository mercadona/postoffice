defmodule Postoffice do
  @moduledoc """
  Postoffice keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger

  alias Postoffice.Messaging
  alias Postoffice.Messaging.Publisher
  alias Postoffice.Messaging.Topic

  def receive_message(message_params) do
    {%{"topic" => topic}, message_attrs} = Map.split(message_params, ["topic"])
    topic = Messaging.get_topic(topic)

    Messaging.create_message(
      topic,
      Map.put_new(message_attrs, "public_id", Ecto.UUID.generate())
    )
  end

  def create_topic(%{"name" => topic_name} = topic_params) do
    case Messaging.get_topic(topic_name) do
      nil ->
        Messaging.create_topic(topic_params)

      topic ->
        {:ok, topic}
    end
  end

  def receive_publisher(%{"topic" => topic} = publisher_params) do
    with %Topic{} = topic <- Messaging.get_topic(topic) do
      publisher =Map.put(publisher_params, "topic_id", topic.id)

      changeset = Publisher.changeset(%Publisher{}, publisher)
      case changeset.valid? do
        true ->
          Postoffice.create_publisher(publisher)
        false ->
          {:error, changeset}
      end
    else
      nil -> {:topic_not_found, {}}
      # nil -> {:error, "topic not found"}
    end
    #   case Messaging.get_topic(topic) do
    #   nil ->
    #     {:error, Publisher.changeset(%Publisher{}, publisher_params)}

    #   topic ->
    #     publisher =Map.put(publisher_params, "topic_id", topic.id)

    #     

    #     case changeset.valid? do
    #       true ->
    #         Postoffice.create_publisher(publisher)

    #       false ->
    #         {:error, changeset}
    #     end
    # end
  end

  def create_publisher(%{"from_now" => from_now} = publisher_params) when from_now == "true" do
    case Messaging.get_last_message() do
      nil ->
        add_publisher(publisher_params, 0)

      %{id: message_id} ->
        add_publisher(publisher_params, message_id)
    end
  end

  def create_publisher(publisher_params) do
    add_publisher(publisher_params, 0)
  end

  defp add_publisher(params, initial_message_id) do
    {_value, publisher_params} = Map.pop(params, "from_now")

    {:ok, publisher} =
      Map.put(publisher_params, "initial_message", initial_message_id)
      |> Messaging.create_publisher()

    {:ok, publisher}
  end

  def find_message_by_uuid(uuid) do
    case Ecto.UUID.cast(uuid) do
      :error ->
        nil

      _ok ->
        Messaging.get_message_by_uuid(uuid)
    end
  end

  def get_message(id), do: Messaging.get_message!(id)

  def get_message_success(message_id), do: Messaging.get_publisher_success_for_message(message_id)

  def get_message_failures(message_id),
    do: Messaging.get_publisher_failures_for_message(message_id)

  def get_last_messages(limit \\ 10), do: Messaging.list_messages(limit)

  def count_received_messages, do: Messaging.count_messages()

  def count_published_messages, do: Messaging.count_published_messages()

  def count_publishers_failures, do: Messaging.count_publishers_failures()

  def count_publishers, do: Messaging.count_publishers()

  def count_topics, do: Messaging.count_topics()

  def ping do
    case :ets.whereis(:counters) do
      :undefined ->
        :ko

      _reference ->
        :ok
    end
  end
end
