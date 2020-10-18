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

  def ping, do: Application.ensure_started(:postoffice)

  def add_messages_to_deliver(messages) do
    messages_number = Enum.count(messages["payload"])
    case messages_number <= get_bulk_messages_limit() do
      false ->
        {:error, "Exceed max messages to ingest in bulk"}
      true ->
        Messaging.add_messages_to_deliver(messages)
    end
  end

  defp get_bulk_messages_limit do
    Application.get_env(:postoffice, :max_bulk_messages, 3000)
  end

end
