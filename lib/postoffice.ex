defmodule Postoffice do
  @moduledoc """
  Postoffice keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  require Logger

  alias Postoffice.Messaging

  def receive_message(%{"topic" => topic} = message_params) do
    case Messaging.get_topic(topic) do
      nil ->
        {:relationship_does_not_exists, %{topic: ["is invalid"]}}

      topic ->
        Messaging.create_message(
          topic,
          Map.put_new(message_params, "public_id", Ecto.UUID.generate())
        )
    end
  end

  def create_topic(topic_params) do
    Messaging.create_topic(topic_params)
  end

  def receive_publisher(%{"topic" => topic} = publisher_params) do
    case Messaging.get_topic(topic) do
      nil ->
        {:relationship_does_not_exists, %{topic: ["is invalid"]}}

      topic ->
        build_publisher(topic, publisher_params)
    end
  end

  defp build_publisher(topic, publisher_params) do
    params = Map.put(publisher_params, "topic_id", topic.id)
    create_publisher(params)
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

    Map.put(publisher_params, "initial_message", initial_message_id)
    |> Messaging.create_publisher()
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

  def ping, do: Application.ensure_started(:postoffice)
end
