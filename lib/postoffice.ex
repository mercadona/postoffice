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
        Messaging.add_message_to_deliver(topic, message_params)
    end
  end

  def receive_messages(%{"topic" => topic, "attributes" => attributes, "payload" => payload} = params) do
    messages_params = Enum.map(payload, fn message_payload ->
      %{attributes: attributes, payload: message_payload}
    end)

    Messaging.add_messages_to_deliver(topic, messages_params)
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

  def find_message_by_id(id) do
    Messaging.get_message!(id)
  end

  def get_message(id), do: Messaging.get_message!(id)

  def get_message_success(message_id), do: Messaging.get_publisher_success_for_message(message_id)

  def get_message_failures(message_id),
    do: Messaging.get_publisher_failures_for_message(message_id)

  def get_last_messages(limit \\ 10), do: Messaging.list_messages(limit)

  def estimated_messages_count, do: Messaging.get_estimated_count("messages")

  def estimated_published_messages_count, do: Messaging.get_estimated_count("publisher_success")

  def count_publishers_failures, do: Messaging.count_publishers_failures_aggregated()

  def count_publishers, do: Messaging.count_publishers()

  def count_pending_messages, do: Messaging.count_pending_messages()

  def count_topics, do: Messaging.count_topics()

  def ping, do: Application.ensure_started(:postoffice)
end
